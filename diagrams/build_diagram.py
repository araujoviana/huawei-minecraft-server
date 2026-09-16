#!/usr/bin/env python3
"""Builds diagrams/architecture.drawio using official Huawei Cloud icons.

Downloads icon + group-container library XML files from
huaweicloud-latam/drawio-libraries (the official Huawei Cloud icon set for
draw.io) and emits a complete mxGraph XML file: resources nested inside the
real VPC / Subnet / Security Group / Auto Scaling Group container shapes,
with short PT-BR callouts next to the parts that matter.
"""
import html
import json
import re
import urllib.parse
import urllib.request

BASE = "https://raw.githubusercontent.com/huaweicloud-latam/drawio-libraries/main/color/"

ICON_FILES = {
    "networking": "HWC Networking (color).xml",
    "compute": "HWC Compute and Containers (color).xml",
    "storage": "HWC Storage (color).xml",
    "mgmt": "HWC Management and Governance (color).xml",
}
GROUPS_FILE = "HWC Groups.xml"

NEEDED_ICONS = {
    "networking": ["Elastic IP (EIP)"],
    "compute": ["Elastic Cloud Server (ECS)"],
    "storage": ["Scalable File Service (SFS) Turbo", "Cloud Backup and Recovery (CBR)"],
    "mgmt": [
        "Cloud Eye Service (CES)",
        "Simple Message Notification (SMN)",
        "Identity and Access Management (IAM)",
    ],
}
NEEDED_GROUPS = [
    "Virtual Private Cloud (VPC)",
    "Subnet",
    "Security Group",
    "Auto Scaling Group (AS Group)",
]


def esc(text):
    """Escape text for use inside an XML attribute value."""
    return html.escape(text, quote=True).replace("\n", "&#10;")


def fetch_library(filename):
    url = BASE + urllib.parse.quote(filename)
    with urllib.request.urlopen(url) as resp:
        content = resp.read().decode("utf-8")
    match = re.search(r"<mxlibrary>(.*)</mxlibrary>", content, re.S)
    return {e["title"]: e for e in json.loads(match.group(1))}


def collect_icons():
    icons = {}
    for category, titles in NEEDED_ICONS.items():
        entries = fetch_library(ICON_FILES[category])
        for title in titles:
            icons[title] = entries[title]
    return icons


def collect_groups():
    """Each group template has cell id=2 (the labeled container box) and
    optionally cell id=3 (a small corner badge icon, positioned at 0,0
    relative to the box)."""
    entries = fetch_library(GROUPS_FILE)
    groups = {}
    for title in NEEDED_GROUPS:
        xml = html.unescape(entries[title]["xml"])
        style = re.search(r'<mxCell id="2"[^>]*style="([^"]*)"', xml).group(1)
        badge_match = re.search(r'<mxCell id="3"[^>]*style="([^"]*)"', xml)
        groups[title] = {"style": style, "badge_style": badge_match.group(1) if badge_match else None}
    return groups


class Builder:
    def __init__(self, icons, groups):
        self.icons = icons
        self.groups = groups
        self.cells = []
        self._next_id = 1

    def _id(self, prefix):
        self._next_id += 1
        return f"{prefix}{self._next_id}"

    def container(self, title, x, y, w, h, parent="1", label=None):
        """Adds a Huawei group container (+ corner badge if it has one) and
        returns its cell id, to be used as `parent` for nested shapes."""
        g = self.groups[title]
        cid = self._id("grp")
        self.cells.append(
            f'<mxCell id="{cid}" value="{esc(label or title)}" style="{g["style"]}container=1;" '
            f'vertex="1" parent="{parent}"><mxGeometry x="{x}" y="{y}" width="{w}" height="{h}" as="geometry"/></mxCell>'
        )
        if g["badge_style"]:
            self.cells.append(
                f'<mxCell id="{cid}_badge" value="" style="{g["badge_style"]}" vertex="1" parent="{cid}">'
                f'<mxGeometry width="30" height="30" as="geometry"/></mxCell>'
            )
        return cid

    def icon(self, title, x, y, parent="1", size=40, label=None):
        data = self.icons[title]
        cid = self._id("icon")
        # A literal ";base64," inside the data URI breaks draw.io's
        # semicolon-delimited style string, truncating the image reference
        # mid-value. Drop the marker (draw.io's image shape still decodes
        # svg+xml data URIs as base64 without it — same format the official
        # group-container badges use).
        image_uri = data["data"].replace(";base64,", ",")
        style = f'shape=image;image={image_uri};verticalLabelPosition=bottom;verticalAlign=top;labelBackgroundColor=#ffffff;'
        self.cells.append(
            f'<mxCell id="{cid}" value="{esc(label if label is not None else title)}" style="{style}" vertex="1" parent="{parent}">'
            f'<mxGeometry x="{x}" y="{y}" width="{size}" height="{size}" as="geometry"/></mxCell>'
        )
        return cid

    def box(self, label, x, y, w, h, fill="#dae8fc", parent="1"):
        cid = self._id("box")
        self.cells.append(
            f'<mxCell id="{cid}" value="{esc(label)}" style="rounded=1;whiteSpace=wrap;html=1;fillColor={fill};" '
            f'vertex="1" parent="{parent}"><mxGeometry x="{x}" y="{y}" width="{w}" height="{h}" as="geometry"/></mxCell>'
        )
        return cid

    def note(self, text, x, y, parent="1"):
        """Small annotation callout: no fill, dashed border, tiny font.
        Size is derived from the text itself so it never wraps/overlaps."""
        cid = self._id("note")
        lines = text.split("\n")
        char_w, line_h, pad = 5.4, 13, 14
        w = max(len(line) for line in lines) * char_w + pad
        h = len(lines) * line_h + pad
        style = (
            "rounded=0;whiteSpace=wrap;html=1;fillColor=none;strokeColor=#999999;"
            "dashed=1;fontSize=9;fontColor=#666666;align=left;verticalAlign=middle;spacing=4;"
        )
        self.cells.append(
            f'<mxCell id="{cid}" value="{esc(text)}" style="{style}" vertex="1" parent="{parent}">'
            f'<mxGeometry x="{x}" y="{y}" width="{w:.0f}" height="{h:.0f}" as="geometry"/></mxCell>'
        )
        return cid

    def edge(self, src, dst, label="", dashed=False, ports=""):
        eid = self._id("edge")
        style = "edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;"
        if dashed:
            style += "dashed=1;"
        style += ports
        self.cells.append(
            f'<mxCell id="{eid}" value="{esc(label)}" style="{style}" edge="1" parent="1" source="{src}" target="{dst}">'
            f'<mxGeometry relative="1" as="geometry"/></mxCell>'
        )

    def xml(self):
        body = "\n".join(self.cells)
        return (
            '<mxfile host="app.diagrams.net">'
            '<diagram name="Minecraft na Huawei Cloud">'
            '<mxGraphModel dx="900" dy="700" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" '
            'arrows="1" fold="1" page="1" pageScale="1" pageWidth="900" pageHeight="800" math="0" shadow="0" '
            'background="#FFFFFF">'
            '<root><mxCell id="0"/><mxCell id="1" parent="0"/>'
            f"{body}"
            "</root></mxGraphModel></diagram></mxfile>"
        )


def build():
    b = Builder(collect_icons(), collect_groups())

    # --- absolute layout ---
    # Every container's children below are given LOCAL coordinates (relative
    # to that container's own top-left). Absolute positions (needed to align
    # the outside-VPC icons with specific inside-VPC rows) are computed by
    # summing each ancestor's origin explicitly — no derived subtraction.
    VPC_X, VPC_Y = 300, 20
    SUBNET_X, SUBNET_Y = VPC_X + 20, VPC_Y + 50
    SG_X, SG_Y = SUBNET_X + 20, SUBNET_Y + 50
    ASG_LOCAL_X, ASG_LOCAL_Y = 20, 60          # within Security Group
    ASG_X, ASG_Y = SG_X + ASG_LOCAL_X, SG_Y + ASG_LOCAL_Y
    ECS_LOCAL_X, ECS_LOCAL_Y = 100, 70         # within Auto Scaling Group (below its note)
    ECS_X, ECS_Y = ASG_X + ECS_LOCAL_X, ASG_Y + ECS_LOCAL_Y
    SFS_LOCAL_X, SFS_LOCAL_Y = 100, 270        # within Security Group (below the AS group)
    SFS_X, SFS_Y = SG_X + SFS_LOCAL_X, SG_Y + SFS_LOCAL_Y

    # Internet -> EIP, aligned with ECS's height so the line into the VPC
    # is a single straight horizontal segment (no jog through container titles)
    internet = b.box("Internet", 40, ECS_Y - 5, 90, 50)
    eip = b.icon("Elastic IP (EIP)", 190, ECS_Y, size=40, label="EIP")
    b.note("reassociado à nova\ninstância na inicialização", 190, ECS_Y + 48)

    vpc = b.container("Virtual Private Cloud (VPC)", VPC_X, VPC_Y, 460, 500)
    subnet = b.container("Subnet", 20, 50, 420, 420, parent=vpc)
    sg = b.container("Security Group", 20, 50, 380, 340, parent=subnet)
    b.note("22/tcp — somente admin_cidr\n25565/tcp — 0.0.0.0/0", 150, 8, parent=sg)

    # Each note sits ABOVE its icon (never beside it) so the icon's own
    # outgoing edge — which exits at the icon's vertical center — never
    # crosses the note.
    asg = b.container("Auto Scaling Group (AS Group)", ASG_LOCAL_X, ASG_LOCAL_Y, 240, 160, parent=sg, label="Auto Scaling Group")
    b.note("min=max=desejado=1\nautorrecuperável, sem LB", 20, 30, parent=asg)
    ecs = b.icon("Elastic Cloud Server (ECS)", ECS_LOCAL_X, ECS_LOCAL_Y, parent=asg, label="ECS")

    b.note("500GB · NFS · dados do mundo", 20, 240, parent=sg)
    sfs = b.icon("Scalable File Service (SFS) Turbo", SFS_LOCAL_X, SFS_LOCAL_Y, parent=sg, label="SFS Turbo")

    iam = b.icon("Identity and Access Management (IAM)", VPC_X + 40, VPC_Y + 540, size=40, label="IAM")
    b.note("agência: permissão para\nreassociar o EIP", VPC_X + 100, VPC_Y + 545)

    # Right side: two independent columns so the two flows never cross.
    # Column A (aligned to SFS Turbo's row): backup only.
    # Column B (aligned to ECS's row): monitoring, CES feeding down into SMN.
    COL_A_X = VPC_X + 460 + 70
    COL_B_X = COL_A_X + 170

    cbr = b.icon("Cloud Backup and Recovery (CBR)", COL_A_X, SFS_Y, label="CBR")
    b.note("7 diários / 4 semanais", COL_A_X + 55, SFS_Y + 12)

    ces = b.icon("Cloud Eye Service (CES)", COL_B_X, ECS_Y, label="CES")
    b.note("CPU≥80% ou\ninstâncias<1 → e-mail", COL_B_X + 55, ECS_Y + 8)

    smn = b.icon("Simple Message Notification (SMN)", COL_B_X, ECS_Y + 220, label="SMN")

    b.edge(internet, eip)
    b.edge(eip, ecs, dashed=True)
    b.edge(ecs, sfs, "NFS")
    b.edge(sfs, cbr, "backup")
    b.edge(ecs, ces)
    b.edge(ces, smn, "alarme")
    b.edge(iam, ecs, "agência", dashed=True)

    return b.xml()


if __name__ == "__main__":
    xml = build()
    with open("diagrams/architecture.drawio", "w", encoding="utf-8") as f:
        f.write(xml)
    print("Wrote diagrams/architecture.drawio")
