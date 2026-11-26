from pathlib import Path

from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_AUTO_SHAPE_TYPE, MSO_CONNECTOR
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.util import Inches, Pt
from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches as DocInches, Pt as DocPt, RGBColor as DocRGB


ROOT = Path(__file__).resolve().parent
PPTX_PATH = ROOT / "NetAdmin-Toolkit-Presentation.pptx"
DOCX_PATH = ROOT / "NetAdmin-Toolkit-Presentation-Script.docx"

BLACK = RGBColor(20, 20, 20)
DARK = RGBColor(34, 34, 34)
MID = RGBColor(100, 100, 100)
LINE = RGBColor(205, 205, 202)
PALE = RGBColor(242, 242, 239)
OFFWHITE = RGBColor(248, 248, 246)
WHITE = RGBColor(255, 255, 255)
FONT = "Arial"


def set_run_font(run, name=FONT, size=18, bold=False, color=BLACK):
    run.font.name = name
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.color.rgb = color


def add_text(slide, x, y, w, h, text, size=18, bold=False, color=BLACK,
             align=PP_ALIGN.LEFT, valign=MSO_ANCHOR.MIDDLE, margin=0.05):
    shape = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = shape.text_frame
    tf.clear()
    tf.margin_left = Inches(margin)
    tf.margin_right = Inches(margin)
    tf.margin_top = Inches(margin)
    tf.margin_bottom = Inches(margin)
    tf.vertical_anchor = valign
    p = tf.paragraphs[0]
    p.alignment = align
    p.space_before = Pt(0)
    p.space_after = Pt(0)
    p.line_spacing = 1.0
    r = p.add_run()
    r.text = text
    set_run_font(r, size=size, bold=bold, color=color)
    return shape


def add_rect(slide, x, y, w, h, fill=WHITE, line=LINE, radius=False):
    kind = MSO_AUTO_SHAPE_TYPE.ROUNDED_RECTANGLE if radius else MSO_AUTO_SHAPE_TYPE.RECTANGLE
    shape = slide.shapes.add_shape(kind, Inches(x), Inches(y), Inches(w), Inches(h))
    shape.fill.solid()
    shape.fill.fore_color.rgb = fill
    shape.line.color.rgb = line
    shape.line.width = Pt(0.8)
    return shape


def add_line(slide, x1, y1, x2, y2, color=LINE, width=1.2, arrow=False):
    conn = slide.shapes.add_connector(
        MSO_CONNECTOR.STRAIGHT, Inches(x1), Inches(y1), Inches(x2), Inches(y2)
    )
    conn.line.color.rgb = color
    conn.line.width = Pt(width)
    # python-pptx does not expose arrowheads consistently across versions.
    # Short connector lines still express flow while remaining fully editable.
    return conn


def base_slide(prs, number, title, eyebrow="NETADMIN TOOLKIT"):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    slide.background.fill.solid()
    slide.background.fill.fore_color.rgb = OFFWHITE
    add_rect(slide, 0, 0, 0.16, 7.5, BLACK, BLACK)
    add_text(slide, 0.60, 0.36, 4.2, 0.28, eyebrow, 10, True, MID)
    add_text(slide, 0.60, 0.72, 9.8, 0.62, title, 28, True, BLACK)
    add_text(slide, 12.05, 7.08, 0.55, 0.20, f"{number:02d}", 9, True, MID, PP_ALIGN.RIGHT)
    return slide


def add_bullet(slide, y, text, x=0.88, w=5.9, size=15, color=DARK):
    add_rect(slide, x, y + 0.18, 0.11, 0.11, DARK, DARK)
    add_text(slide, x + 0.28, y, w, 0.49, text, size, False, color)


def make_deck():
    prs = Presentation()
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)
    # Remove implicit slide by only using blank presentation layouts; python-pptx starts with none.

    # Slide 1 - Cover
    s = prs.slides.add_slide(prs.slide_layouts[6])
    s.background.fill.solid(); s.background.fill.fore_color.rgb = OFFWHITE
    add_rect(s, 0, 0, 0.16, 7.5, BLACK, BLACK)
    add_text(s, 0.66, 0.48, 4.4, 0.26, "MÔN QUẢN TRỊ MẠNG", 10, True, MID)
    add_text(s, 0.66, 1.18, 11.50, 0.95, "NETADMIN TOOLKIT", 38, True, BLACK)
    add_text(s, 0.66, 2.10, 10.95, 0.78,
             "Bộ công cụ tự động cấu hình và quản trị mạng trên CentOS", 21, False, DARK)
    add_line(s, 0.66, 3.05, 12.16, 3.05, LINE, 1.0)
    add_text(s, 0.66, 3.40, 2.40, 0.30, "NHÓM THỰC HIỆN", 10, True, MID)
    members = [
        ("3122560035", "Đoàn Văn Khoan"),
        ("3123560023", "Trần Gia Hân"),
        ("3124560091", "Nguyễn Vương Hoàng Tịnh"),
        ("3123560056", "Nguyễn Thành Nhân"),
    ]
    for i, (student_id, name) in enumerate(members):
        y = 4.00 + i * 0.58
        add_text(s, 0.66, y, 1.85, 0.34, student_id, 14, True, BLACK)
        add_text(s, 2.62, y, 4.70, 0.34, name, 15, False, DARK)
    add_text(s, 11.86, 7.08, 0.55, 0.20, "01", 9, True, MID, PP_ALIGN.RIGHT)

    # Slide 2
    s = base_slide(prs, 2, "Mục đích đề tài")
    add_text(s, 0.60, 1.40, 6.55, 0.74,
             "Biến các bài thực hành quản trị mạng trên CentOS thành một quy trình thống nhất, dễ quan sát và an toàn hơn.",
             17, False, RGBColor(72, 72, 72))
    add_rect(s, 0.60, 2.36, 7.18, 3.78, WHITE, LINE, True)
    add_text(s, 0.88, 2.56, 4.0, 0.32, "VẤN ĐỀ CẦN GIẢI QUYẾT", 11, True, BLACK)
    add_bullet(s, 3.04, "Nhiều lệnh, tệp cấu hình và dịch vụ phải nhớ đồng thời.", w=6.25)
    add_bullet(s, 3.86, "Người mới khó nhận biết thao tác nào an toàn và thao tác nào làm thay đổi hệ thống.", w=6.25)
    add_bullet(s, 4.84, "Kết quả thực thi phân tán, khó kiểm tra và khó lặp lại khi học.", w=6.25)
    add_rect(s, 8.10, 2.36, 4.63, 3.78, DARK, DARK, True)
    add_text(s, 8.43, 2.62, 3.75, 0.28, "KẾT QUẢ HƯỚNG TỚI", 10, True, RGBColor(200, 200, 200))
    add_text(s, 8.42, 3.10, 1.05, 0.80, "8", 43, True, WHITE)
    add_text(s, 9.48, 3.32, 2.70, 0.34, "nhóm công cụ", 17, False, RGBColor(230, 230, 230))
    add_text(s, 8.42, 4.18, 1.55, 0.80, "123", 43, True, WHITE)
    add_text(s, 9.82, 4.40, 2.10, 0.34, "thao tác UI", 17, False, RGBColor(230, 230, 230))
    add_text(s, 8.43, 5.35, 3.78, 0.48,
             "CLI thống nhất · Cockpit UI\nDry run · xác nhận · backup", 13, False, RGBColor(205, 205, 205))
    add_text(s, 0.60, 6.58, 10.9, 0.34,
             "Trọng tâm: hỗ trợ học và thực hành quản trị mạng, đồng thời vẫn hiển thị lệnh Bash bên dưới.",
             12, False, MID)

    # Slide 3
    s = base_slide(prs, 3, "Mô hình của đề tài")
    add_text(s, 0.60, 1.34, 11.5, 0.42,
             "Một luồng thực thi duy nhất từ giao diện Cockpit đến các dịch vụ của CentOS.",
             15, False, MID)
    layers = [
        ("NGƯỜI DÙNG", "Trình duyệt trên máy quản trị", 1.92, 1.16, WHITE, BLACK),
        ("GIAO DIỆN", "Cockpit NetAdmin Tools", 2.72, 1.16, PALE, BLACK),
        ("CLI THỐNG NHẤT", "/usr/local/bin/netadmin", 3.52, 1.16, DARK, WHITE),
        ("CORE DÙNG CHUNG", "Validation · Log · Backup · System runner", 4.32, 1.16, PALE, BLACK),
    ]
    for label, value, y, h, fill, text_color in layers:
        add_rect(s, 2.05, y, 8.10, h - 0.18, fill, LINE if fill != DARK else DARK, True)
        add_text(s, 2.34, y + 0.10, 2.15, 0.42, label, 10, True, text_color)
        add_text(s, 4.38, y + 0.08, 5.35, 0.44, value, 16, fill == DARK, text_color)
        if y < 4.32:
            add_line(s, 6.10, y + 0.98, 6.10, y + 1.08, MID, 1.3, True)
    add_text(s, 10.48, 2.34, 1.95, 0.38, "DRY RUN", 10, True, MID, PP_ALIGN.CENTER)
    add_text(s, 10.46, 2.72, 1.98, 0.83, "Xem lệnh\ntrước khi chạy", 13, False, DARK, PP_ALIGN.CENTER)
    add_line(s, 10.18, 3.15, 10.44, 3.15, MID, 1.2, True)
    add_text(s, 10.48, 4.16, 1.95, 0.38, "THỰC THI", 10, True, MID, PP_ALIGN.CENTER)
    add_text(s, 10.46, 4.54, 1.98, 0.83, "Cockpit spawn\nvới quyền quản trị", 13, False, DARK, PP_ALIGN.CENTER)
    add_line(s, 10.18, 4.95, 10.44, 4.95, MID, 1.2, True)
    modules = ["Doctor", "DNS", "DHCP", "Storage", "Samba", "Web", "FTP", "Mail"]
    x0, y0, gap, mw = 0.62, 5.43, 0.13, 1.42
    for i, name in enumerate(modules):
        x = x0 + i * (mw + gap)
        add_rect(s, x, y0, mw, 0.58, WHITE, LINE, True)
        add_text(s, x, y0 + 0.07, mw, 0.34, name, 11, True, BLACK, PP_ALIGN.CENTER)
    add_line(s, 6.10, 5.30, 6.10, 5.43, MID, 1.3, True)
    add_rect(s, 0.62, 6.25, 12.10, 0.52, PALE, LINE, True)
    add_text(s, 0.82, 6.32, 11.70, 0.28,
             "CentOS: NetworkManager · BIND · dhcpd · Samba · Apache · vsftpd · Postfix/Dovecot · systemd · firewalld · SELinux",
             11, False, DARK, PP_ALIGN.CENTER)

    # Slide 4
    s = base_slide(prs, 4, "Các bước để thực hiện")
    add_text(s, 0.60, 1.34, 11.5, 0.42,
             "Trình bày ở mức quy trình tổng quan; mỗi tính năng vẫn được triển khai độc lập theo module.",
             15, False, MID)
    steps = [
        ("01", "Khảo sát", "Bài học, AutoScript\nvà yêu cầu CentOS"),
        ("02", "Chuẩn hóa", "Use case thành\nhợp đồng CLI"),
        ("03", "Tổ chức", "Core dùng chung\nvà module độc lập"),
        ("04", "Tích hợp", "Cockpit UI gọi\ncùng lệnh netadmin"),
        ("05", "Kiểm tra", "Cú pháp → dịch vụ\n→ client thật"),
    ]
    start_x, y, card_w, card_h, gap = 0.60, 2.10, 2.25, 3.28, 0.27
    for i, (num, title, desc) in enumerate(steps):
        x = start_x + i * (card_w + gap)
        fill = DARK if i == 2 else WHITE
        textc = WHITE if i == 2 else BLACK
        subc = RGBColor(205, 205, 205) if i == 2 else MID
        add_rect(s, x, y, card_w, card_h, fill, DARK if i == 2 else LINE, True)
        add_text(s, x + 0.23, y + 0.22, 0.70, 0.34, num, 11, True, subc)
        add_text(s, x + 0.23, y + 1.05, card_w - 0.46, 0.48, title, 20, True, textc)
        add_text(s, x + 0.23, y + 1.72, card_w - 0.46, 1.04, desc, 14, False, subc)
        if i < len(steps) - 1:
            add_line(s, x + card_w + 0.04, y + 1.62, x + card_w + gap - 0.04, y + 1.62, MID, 1.1, True)
    add_rect(s, 0.60, 5.80, 12.00, 0.72, PALE, LINE, True)
    add_text(s, 0.88, 5.92, 11.45, 0.38,
             "Nguyên tắc xuyên suốt: giao diện và CLI dùng cùng hợp đồng lệnh; firewall và SELinux vẫn được giữ hoạt động.",
             13, True, DARK, PP_ALIGN.CENTER)

    # Slide 5
    s = prs.slides.add_slide(prs.slide_layouts[6])
    s.background.fill.solid(); s.background.fill.fore_color.rgb = BLACK
    add_text(s, 1.2, 2.38, 10.95, 1.55, "DEMO", 58, True, WHITE, PP_ALIGN.CENTER)

    # Slide 6
    s = base_slide(prs, 6, "Kết luận")
    add_text(s, 0.60, 1.48, 11.9, 0.82,
             "NetAdmin Toolkit gom các bài thực hành quản trị mạng vào một quy trình thống nhất, có thể quan sát và kiểm soát.",
             20, True, BLACK)
    add_rect(s, 0.60, 2.58, 7.52, 3.52, WHITE, LINE, True)
    add_text(s, 0.88, 2.80, 3.70, 0.32, "KẾT QUẢ ĐẠT ĐƯỢC", 11, True, BLACK)
    conclusions = [
        "8 nhóm công cụ, 123 thao tác trên Cockpit.",
        "CLI và giao diện dùng cùng một hợp đồng lệnh.",
        "Có validation, Dry run, xác nhận và backup/rollback.",
        "Kiến trúc module giúp bổ sung lệnh mới dễ hơn.",
    ]
    for i, t in enumerate(conclusions):
        add_bullet(s, 3.22 + i * 0.62, t, x=0.92, w=6.75, size=14)
    add_rect(s, 8.44, 2.58, 4.28, 3.52, PALE, LINE, True)
    add_text(s, 8.74, 2.80, 3.52, 0.32, "GIỚI HẠN VÀ HƯỚNG TIẾP", 11, True, BLACK)
    add_text(s, 8.74, 3.30, 3.48, 1.18,
             "Mỗi dịch vụ vẫn cần kiểm tra bằng client thật và phụ thuộc package, phiên bản CentOS.",
             15, False, DARK)
    add_text(s, 8.74, 4.74, 3.48, 0.92,
             "Tiếp tục mở rộng module, chuẩn hóa tài liệu và tăng khả năng phục hồi cấu hình.",
             15, True, DARK)
    add_text(s, 0.60, 6.54, 11.6, 0.36,
             "Giá trị cốt lõi: người học hiểu lệnh đang chạy, thay vì chỉ bấm nút và bỏ qua kiến thức hệ thống.",
             12, False, MID)

    # Slide 7
    s = base_slide(prs, 7, "Phân công công việc của nhóm")
    add_text(s, 0.60, 1.34, 11.5, 0.42,
             "Phân chia theo module, đồng thời phối hợp kiểm tra chéo giữa CLI, giao diện và tài liệu.", 15, False, MID)
    rows, cols = 5, 3
    table_shape = s.shapes.add_table(rows, cols, Inches(0.72), Inches(1.88), Inches(11.90), Inches(4.86))
    table = table_shape.table
    table.columns[0].width = Inches(1.72)
    table.columns[1].width = Inches(2.18)
    table.columns[2].width = Inches(8.00)
    table.rows[0].height = Inches(0.58)
    for row_index in range(1, rows):
        table.rows[row_index].height = Inches(1.07)
    headers = ["Mã số sinh viên", "Họ và tên", "Nhiệm vụ"]
    assignments = [
        ("3122560035", "Đoàn Văn Khoan", "Kiến trúc và core hệ thống",
         "CLI/netadmin, Doctor, logging, validation, dry run, backup/rollback; quy ước mã nguồn; tài liệu kiến trúc và slide."),
        ("3123560023", "Trần Gia Hân", "Network, DHCP và DNS",
         "NetworkManager, dhcpd, BIND; thao tác cấu hình, kiểm tra, firewall; mô hình hai card mạng; hướng dẫn cài đặt và vận hành."),
        ("3124560091", "Nguyễn Vương Hoàng Tịnh", "Storage và Samba",
         "Disk, partition, filesystem, mount, LVM, quota; SMB, user và quyền truy cập; xác nhận thao tác, backup, SELinux và kiểm thử lưu trữ."),
        ("3123560056", "Nguyễn Thành Nhân", "Web, FTP, Mail và giao diện Cockpit",
         "Apache, vsftpd, Postfix, Dovecot; danh mục tool, form, xem trước lệnh, PTY và lịch sử; tích hợp CentOS, kiểm thử và hướng dẫn UI."),
    ]
    for r in range(rows):
        for c in range(cols):
            cell = table.cell(r, c)
            cell.margin_left = Inches(0.11); cell.margin_right = Inches(0.11)
            cell.margin_top = Inches(0.07); cell.margin_bottom = Inches(0.07)
            cell.vertical_anchor = MSO_ANCHOR.MIDDLE
            cell.fill.solid(); cell.fill.fore_color.rgb = DARK if r == 0 else WHITE
            cell.text = headers[c] if r == 0 else assignments[r - 1][c]
            p = cell.text_frame.paragraphs[0]
            p.alignment = PP_ALIGN.CENTER if c < 2 else PP_ALIGN.LEFT
            if p.runs:
                set_run_font(p.runs[0], size=11.5 if r == 0 else 11, bold=(r == 0), color=WHITE if r == 0 else BLACK)
    for r, (_, _, role, detail) in enumerate(assignments, start=1):
        cell = table.cell(r, 2)
        tf = cell.text_frame
        tf.clear()
        role_p = tf.paragraphs[0]
        role_p.alignment = PP_ALIGN.LEFT
        role_p.space_after = Pt(2)
        role_run = role_p.add_run(); role_run.text = role
        set_run_font(role_run, size=11, bold=True, color=BLACK)
        detail_p = tf.add_paragraph()
        detail_p.alignment = PP_ALIGN.LEFT
        detail_p.space_before = Pt(0); detail_p.space_after = Pt(0)
        detail_run = detail_p.add_run(); detail_run.text = detail
        set_run_font(detail_run, size=9.5, bold=False, color=DARK)
    # Explicit editable grid lines keep the table consistent in PowerPoint and Impress.
    grid_x = [0.72, 2.44, 4.62, 12.62]
    grid_y = [1.88, 2.46, 3.53, 4.60, 5.67, 6.74]
    for x in grid_x:
        add_line(s, x, grid_y[0], x, grid_y[-1], LINE, 0.8)
    for y in grid_y:
        add_line(s, grid_x[0], y, grid_x[-1], y, LINE, 0.8)

    # Slide 8 - Thank you
    s = prs.slides.add_slide(prs.slide_layouts[6])
    s.background.fill.solid(); s.background.fill.fore_color.rgb = BLACK
    add_text(s, 1.2, 2.30, 10.95, 1.35, "CẢM ƠN", 54, True, WHITE, PP_ALIGN.CENTER)
    add_text(s, 3.55, 3.80, 6.25, 0.38, "NHÓM NETADMIN TOOLKIT", 11, True, RGBColor(185, 185, 185), PP_ALIGN.CENTER)
    add_text(s, 11.86, 7.08, 0.55, 0.20, "08", 9, True, RGBColor(145, 145, 145), PP_ALIGN.RIGHT)
    prs.save(PPTX_PATH)


def set_doc_font(run, size=11, bold=False, color="000000", italic=False):
    run.font.name = FONT
    run._element.get_or_add_rPr().rFonts.set(qn("w:ascii"), FONT)
    run._element.get_or_add_rPr().rFonts.set(qn("w:hAnsi"), FONT)
    run.font.size = DocPt(size)
    run.font.bold = bold
    run.font.italic = italic
    run.font.color.rgb = DocRGB.from_string(color)


def shade_cell(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_borders(cell, color="D9D9D9", size="6"):
    tc_pr = cell._tc.get_or_add_tcPr()
    borders = tc_pr.first_child_found_in("w:tcBorders")
    if borders is None:
        borders = OxmlElement("w:tcBorders")
        tc_pr.append(borders)
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        tag = "w:" + edge
        element = borders.find(qn(tag))
        if element is None:
            element = OxmlElement(tag)
            borders.append(element)
        element.set(qn("w:val"), "single")
        element.set(qn("w:sz"), size)
        element.set(qn("w:color"), color)


def add_doc_heading(doc, text, level=1):
    p = doc.add_paragraph(style=f"Heading {level}")
    p.paragraph_format.space_before = DocPt(12 if level == 1 else 8)
    p.paragraph_format.space_after = DocPt(5)
    r = p.add_run(text)
    set_doc_font(r, size=15 if level == 1 else 12, bold=True)
    return p


def add_doc_para(doc, text="", bold_lead=None, italic=False):
    p = doc.add_paragraph()
    p.paragraph_format.space_after = DocPt(5)
    p.paragraph_format.line_spacing = 1.12
    if bold_lead and text.startswith(bold_lead):
        r1 = p.add_run(bold_lead); set_doc_font(r1, bold=True)
        r2 = p.add_run(text[len(bold_lead):]); set_doc_font(r2, italic=italic)
    else:
        r = p.add_run(text); set_doc_font(r, italic=italic)
    return p


def add_doc_bullet(doc, text):
    p = doc.add_paragraph(style="List Bullet")
    p.paragraph_format.space_after = DocPt(3)
    p.paragraph_format.line_spacing = 1.08
    r = p.add_run(text); set_doc_font(r)
    return p


def add_step(doc, number, title, time, action, say, expected=None):
    add_doc_heading(doc, f"Bước {number}  {title}  {time}", 2)
    add_doc_para(doc, "Thao tác trên UI: " + action, bold_lead="Thao tác trên UI: ")
    add_doc_para(doc, "Lời trình bày: " + say, bold_lead="Lời trình bày: ")
    if expected:
        add_doc_para(doc, "Kết quả cần chỉ ra: " + expected, bold_lead="Kết quả cần chỉ ra: ")


def make_script():
    doc = Document()
    section = doc.sections[0]
    section.top_margin = DocInches(0.70); section.bottom_margin = DocInches(0.70)
    section.left_margin = DocInches(0.82); section.right_margin = DocInches(0.82)
    section.page_width = DocInches(8.5); section.page_height = DocInches(11)
    styles = doc.styles
    for name in ["Normal", "Title", "Heading 1", "Heading 2", "List Bullet"]:
        style = styles[name]
        style.font.name = FONT
        style._element.rPr.rFonts.set(qn("w:ascii"), FONT)
        style._element.rPr.rFonts.set(qn("w:hAnsi"), FONT)
        style.font.color.rgb = DocRGB(0, 0, 0)
    styles["Normal"].font.size = DocPt(11)

    p = doc.add_paragraph(style="Title")
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    p.paragraph_format.space_after = DocPt(10)
    r = p.add_run("Kịch bản trình bày dự án NetAdmin Toolkit")
    set_doc_font(r, size=22, bold=True)
    add_doc_para(doc,
                 "Kịch bản này đi theo đúng 8 slide và dành phần lớn thời gian cho demo trực tiếp trên Cockpit. Mốc chuẩn là 27 phút; có thể rút còn 20 phút hoặc kéo đến 30 phút mà không thay đổi cấu trúc.")

    add_doc_heading(doc, "Phân bổ thời gian", 1)
    table = doc.add_table(rows=1, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    widths = [DocInches(1.2), DocInches(4.4), DocInches(1.2)]
    headers = ["Phần", "Nội dung", "Thời lượng"]
    for i, cell in enumerate(table.rows[0].cells):
        cell.width = widths[i]; cell.text = headers[i]; shade_cell(cell, "2B2B2B"); set_cell_borders(cell)
        cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
        for run in cell.paragraphs[0].runs: set_doc_font(run, size=10, bold=True, color="FFFFFF")
    timing = [
        ("Slide 1", "Chủ đề và nhóm thực hiện", "1 phút"),
        ("Slide 2", "Mục đích đề tài", "3 phút"),
        ("Slide 3", "Mô hình của đề tài", "4 phút"),
        ("Slide 4", "Các bước thực hiện", "3 phút"),
        ("Slide 5", "Demo trực tiếp trên Cockpit", "12–14 phút"),
        ("Slide 6", "Kết luận", "2 phút"),
        ("Slide 7", "Phân công công việc", "1 phút"),
        ("Slide 8", "Cảm ơn", "30 giây"),
    ]
    for row_index, data in enumerate(timing, start=1):
        cells = table.add_row().cells
        for i, value in enumerate(data):
            cells[i].width = widths[i]; cells[i].text = value; set_cell_borders(cells[i])
            shade_cell(cells[i], "F4F4F2" if row_index % 2 == 0 else "FFFFFF")
            cells[i].vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            cells[i].paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER if i != 1 else WD_ALIGN_PARAGRAPH.LEFT
            for run in cells[i].paragraphs[0].runs: set_doc_font(run, size=10)

    add_doc_heading(doc, "Chuẩn bị trước khi trình bày", 1)
    for item in [
        "Mở Cockpit tại https://IP-CENTOS:9090, đăng nhập và chọn NetAdmin Tools.",
        "Kiểm tra dòng trạng thái Cockpit đã kết nối và bật Administrative access nếu phiên làm việc yêu cầu quyền quản trị.",
        "Giữ Dry run ở trạng thái bật trước khi demo cấu hình. Trình duyệt nên để zoom 100%.",
        "Chuẩn bị sẵn một cửa sổ Terminal để dùng khi giao diện hoặc mạng có sự cố.",
        "Không thực thi thao tác phá hủy dữ liệu. Phần Storage chỉ dùng để trình bày cơ chế xác nhận mục tiêu.",
    ]:
        add_doc_bullet(doc, item)

    add_doc_heading(doc, "Slide 1  Chủ đề và nhóm thực hiện  khoảng 1 phút", 1)
    add_doc_para(doc,
        "Lời trình bày: “Kính thưa thầy cô và các bạn. Nhóm em xin trình bày đề tài NetAdmin Toolkit, bộ công cụ tự động cấu hình và quản trị mạng trên CentOS. Nhóm thực hiện gồm Đoàn Văn Khoan, Trần Gia Hân, Nguyễn Vương Hoàng Tịnh và Nguyễn Thành Nhân.”",
        bold_lead="Lời trình bày: ")
    add_doc_para(doc,
        "Chuyển cảnh: “Trước tiên, nhóm em xin trình bày mục đích và vấn đề mà đề tài cần giải quyết.”",
        bold_lead="Chuyển cảnh: ")

    add_doc_heading(doc, "Slide 2  Mục đích đề tài  khoảng 3 phút", 1)
    add_doc_para(doc,
        "Lời trình bày: “Đề tài của nhóm em là NetAdmin Toolkit, một bộ công cụ Bash có giao diện Cockpit để hỗ trợ các bài thực hành quản trị mạng trên CentOS. Vấn đề ban đầu là mỗi dịch vụ có một nhóm lệnh, tệp cấu hình và cách kiểm tra khác nhau. Với người mới, việc nhớ đúng cú pháp đã khó, nhưng khó hơn là biết thao tác nào chỉ đọc thông tin và thao tác nào thật sự thay đổi hệ thống.”",
        bold_lead="Lời trình bày: ")
    add_doc_para(doc,
        "“Mục tiêu của nhóm không phải che giấu Linux bằng các nút bấm. Giao diện luôn hiển thị lệnh Bash tương ứng để người học hiểu hệ thống đang làm gì. Dự án hiện gom 8 nhóm công cụ với 123 thao tác, dùng chung một CLI, có chế độ Dry run, xác nhận thao tác nhạy cảm và cơ chế backup.”")
    add_doc_para(doc, "Điểm cần chỉ trên slide: lần lượt chỉ vào ba vấn đề, sau đó nhấn mạnh hai số 8 và 123.", bold_lead="Điểm cần chỉ trên slide: ")

    add_doc_heading(doc, "Slide 3  Mô hình của đề tài  khoảng 4 phút", 1)
    add_doc_para(doc,
        "Lời trình bày: “Luồng hoạt động bắt đầu từ trình duyệt. Người dùng chọn công cụ trên Cockpit, nhập tham số và xem trước lệnh. Cockpit không gọi trực tiếp từng dịch vụ mà gọi một điểm vào duy nhất là netadmin.”",
        bold_lead="Lời trình bày: ")
    add_doc_para(doc,
        "“Bên dưới CLI là core dùng chung gồm kiểm tra dữ liệu đầu vào, ghi log, sao lưu và bộ chạy lệnh hệ thống. Các nghiệp vụ được tách thành 8 module: Doctor, DNS, DHCP, Storage, Samba, Web, FTP và Mail. Cuối cùng, từng module làm việc với dịch vụ thật của CentOS như NetworkManager, BIND, dhcpd, Samba, Apache, vsftpd, Postfix và Dovecot.”")
    add_doc_para(doc,
        "“Có hai chế độ. Dry run chỉ tạo và hiển thị lệnh nên phù hợp khi học hoặc kiểm tra tham số. Khi tắt Dry run, Cockpit mới thực thi lệnh với quyền quản trị. Vì UI và Terminal dùng cùng một hợp đồng lệnh nên kết quả nhất quán và dễ kiểm tra.”")
    add_doc_para(doc, "Thao tác trình chiếu: đi từ trên xuống theo các tầng, rồi chỉ sang hai nhánh Dry run và Thực thi.", bold_lead="Thao tác trình chiếu: ")

    add_doc_heading(doc, "Slide 4  Các bước để thực hiện  khoảng 3 phút", 1)
    add_doc_para(doc,
        "Lời trình bày: “Nhóm triển khai theo năm bước tổng quát. Đầu tiên là khảo sát nội dung môn học và các AutoScript hiện có. Tiếp theo, nhóm chuyển từng use case thành một hợp đồng CLI rõ ràng. Sau đó, phần dùng chung được đưa vào core và từng dịch vụ được tách thành module độc lập. Bước bốn là tích hợp Cockpit nhưng vẫn gọi đúng CLI đó. Cuối cùng, nhóm kiểm tra theo ba lớp: cú pháp, trạng thái dịch vụ và kiểm tra từ client thật.”",
        bold_lead="Lời trình bày: ")
    add_doc_para(doc,
        "“Nguyên tắc xuyên suốt là không tắt firewall hoặc SELinux để né lỗi. Công cụ phải cấu hình đúng trong điều kiện bảo vệ của CentOS vẫn hoạt động.”")
    add_doc_para(doc, "Chuyển cảnh: “Sau đây em xin chuyển sang phần quan trọng nhất là demo trực tiếp.”", bold_lead="Chuyển cảnh: ")

    add_doc_heading(doc, "Slide 5  Demo trực tiếp  12 đến 14 phút", 1)
    add_doc_para(doc,
        "Khi slide DEMO xuất hiện, không đọc thêm nội dung trên slide. Chuyển ngay sang cửa sổ Cockpit đã chuẩn bị. Trong toàn bộ demo, luôn nói theo ba ý: tôi đang chọn gì, lệnh nào sẽ chạy và kết quả này chứng minh điều gì.")

    add_step(doc, 1, "Giới thiệu nhanh giao diện", "1 phút",
        "Mở NetAdmin Tools. Chỉ vào danh sách module, ô tìm kiếm, khu vực chi tiết bên phải, công tắc Dry run và trạng thái Cockpit đã kết nối.",
        "“Đây là giao diện quản lý các công cụ. Bên trái là 8 module, giữa là danh sách thao tác, bên phải là tham số và lệnh Bash tương ứng. Dry run đang bật nên các thao tác cấu hình trong phần demo chưa thay đổi máy.”",
        "Người xem hiểu bố cục và thấy rõ trạng thái an toàn trước khi chạy lệnh.")

    add_step(doc, 2, "Kiểm tra môi trường bằng Doctor", "2 phút",
        "Chọn Doctor → Kiểm tra môi trường → Chạy tool. Mở hộp Kết quả thực thi và cuộn chậm qua các dòng chính.",
        "“Doctor là bước nên chạy đầu tiên. Nó kiểm tra các điều kiện chung như hệ điều hành, quyền, các lệnh hệ thống và môi trường mà các module khác cần dùng. Nhờ đó, nếu một công cụ thất bại, người dùng có thông tin để phân biệt lỗi môi trường với lỗi cấu hình dịch vụ.”",
        "Chỉ ra exit status và một vài dòng [OK] hoặc cảnh báo. Không cần đọc toàn bộ output.")

    add_step(doc, 3, "Quan sát cấu hình mạng", "2 phút",
        "Chọn DNS → Liệt kê kết nối mạng → Chạy tool. Đối chiếu tên connection, interface và trạng thái đang hoạt động.",
        "“DNS và DHCP phụ thuộc trực tiếp vào interface và connection của NetworkManager. Công cụ này giúp người mới lấy đúng tên kết nối trước khi cấu hình IP hoặc dịch vụ. Đây cũng là lý do dự án không hard-code enp2s0 hay một tên card mạng cố định.”",
        "Ít nhất một connection phải hiển thị; giải thích interface thực tế có thể khác giữa các máy ảo.")

    add_step(doc, 4, "Tạo DHCP scope ở chế độ Dry run", "4 phút",
        "Chọn DHCP → Tạo DHCP scope. Nhập: lab; 192.168.10.0; 255.255.255.0; 192.168.10.100; 192.168.10.200; 192.168.10.1; 192.168.10.2; lab.local; 86400. Giữ Dry run bật. Quan sát lệnh xem trước rồi bấm Chạy tool.",
        "“Đây là use case có nhiều tham số nên rất dễ nhập sai khi làm thủ công. Giao diện tổ chức chúng thành các trường có ý nghĩa. Trước khi chạy, chúng ta vẫn nhìn thấy lệnh netadmin hoàn chỉnh. Vì Dry run đang bật, công cụ chỉ kiểm tra và mô phỏng thao tác, chưa ghi cấu hình DHCP thật.”",
        "Chỉ ra lệnh được tạo, exit status và thông báo Dry run. Nhấn mạnh đây là minh chứng UI và CLI dùng cùng một hợp đồng lệnh.")

    add_step(doc, 5, "Kiểm tra cấu hình DNS", "2 phút",
        "Chọn DNS → DNS config: check → Chạy tool. Nếu BIND đã được cấu hình, chỉ kết quả kiểm tra; nếu chưa, dùng thông báo để giải thích trạng thái môi trường.",
        "“Sau khi tạo hoặc sửa cấu hình, bước kiểm tra cú pháp phải diễn ra trước khi restart dịch vụ. Công cụ gói thao tác kiểm tra BIND thành một use case rõ ràng và trả output gốc để người học vẫn nhận biết lỗi thật của named.”",
        "Kết quả hợp lệ hoặc thông báo thiếu cấu hình đều dùng được; không sửa hệ thống ngay trong lúc trình bày.")

    add_step(doc, 6, "Trình bày an toàn của Storage", "2 phút",
        "Chọn Storage → Liệt kê ổ đĩa → Chạy tool. Sau đó mở Tạo partition, nhập hoặc giữ mục tiêu /dev/sdb nhưng không thực thi. Chỉ vào yêu cầu xác nhận đúng tên thiết bị.",
        "“Storage là nhóm có rủi ro cao nhất. Vì vậy dự án tách thao tác chỉ đọc và thao tác thay đổi dữ liệu. Với tạo partition, ngoài tham số kỹ thuật, người dùng phải xác nhận chính xác mục tiêu. Trong buổi demo em không chạy lệnh này để tránh thay đổi ổ đĩa.”",
        "Cho thấy danh sách ổ đĩa và cơ chế xác nhận; tuyệt đối không tắt Dry run hoặc bấm thực thi thật.")

    add_step(doc, 7, "Tổng kết lịch sử lệnh", "1 đến 2 phút",
        "Mở Lệnh vừa chạy hoặc khu vực lịch sử. Chỉ lại chuỗi Doctor → Network → DHCP Dry run → DNS check → Storage list.",
        "“Lịch sử này giúp người dùng biết mình vừa chạy lệnh nào và quay lại kiểm tra output. Như vậy UI không chỉ là nơi bấm nút mà còn tạo một luồng học: chọn use case, xem lệnh, chạy, đọc kết quả và kiểm tra lại.”",
        "Kết thúc demo bằng câu: “Phần demo cho thấy các module khác nhau vẫn dùng một trải nghiệm và một hợp đồng lệnh thống nhất.”")

    add_doc_heading(doc, "Phương án dự phòng khi demo gặp lỗi", 1)
    add_doc_para(doc,
        "Nếu Cockpit mất kết nối, giữ bình tĩnh và nói: “Giao diện đang mất runtime Cockpit, nhưng toàn bộ use case dùng cùng CLI nên em chuyển sang Terminal để minh họa.” Sau đó chạy các lệnh an toàn dưới đây. Không cố sửa mạng trong lúc trình bày.")
    commands = [
        "sudo ./bin/netadmin doctor",
        "sudo ./bin/netadmin dns network list",
        "NETADMIN_DRY_RUN=1 sudo ./bin/netadmin dhcp scope add lab 192.168.10.0 255.255.255.0 192.168.10.100 192.168.10.200 192.168.10.1 192.168.10.2 lab.local 86400",
        "sudo ./bin/netadmin storage disk list",
    ]
    for cmd in commands:
        p = doc.add_paragraph()
        p.paragraph_format.left_indent = DocInches(0.25)
        p.paragraph_format.space_after = DocPt(3)
        r = p.add_run(cmd); set_doc_font(r, size=9, color="303030")

    add_doc_heading(doc, "Slide 6  Kết luận  khoảng 2 phút", 1)
    add_doc_para(doc,
        "Lời trình bày: “Qua phần demo, có thể thấy kết quả chính của đề tài không chỉ là số lượng công cụ. Quan trọng hơn là các công cụ được đặt trong cùng một quy trình: chọn use case, xem lệnh, kiểm tra tham số, thực thi và đọc output.”",
        bold_lead="Lời trình bày: ")
    add_doc_para(doc,
        "“Dự án hiện có 8 nhóm với 123 thao tác. UI và CLI dùng cùng hợp đồng lệnh; core cung cấp validation, Dry run, xác nhận và backup. Kiến trúc module giúp nhóm bổ sung bài học mới mà không phải viết lại toàn bộ giao diện hoặc phần chạy lệnh.”")
    add_doc_para(doc,
        "“Giới hạn hiện tại là việc nghiệm thu còn phụ thuộc package và phiên bản CentOS. Một dịch vụ được cấu hình đúng vẫn cần kiểm tra bằng client thật. Hướng phát triển là mở rộng module, chuẩn hóa thêm tài liệu và hoàn thiện khả năng phục hồi cấu hình.”")
    add_doc_para(doc,
        "Câu chốt: “Giá trị cốt lõi của NetAdmin Toolkit là giúp người học thao tác dễ hơn nhưng vẫn hiểu lệnh Bash và dịch vụ thật đang chạy bên dưới.”",
        bold_lead="Câu chốt: ")

    add_doc_heading(doc, "Slide 7  Phân công công việc  khoảng 1 phút", 1)
    add_doc_para(doc,
        "Lời trình bày sau khi nhóm đã điền bảng: “Cuối cùng là phần phân công công việc. Nhóm chia nhiệm vụ theo các mảng code Bash và kiến trúc, tích hợp giao diện Cockpit, kiểm thử và setup CentOS, tài liệu và báo cáo. Các thành viên phối hợp kiểm tra chéo để bảo đảm command, UI và tài liệu mô tả cùng một hành vi.”",
        bold_lead="Lời trình bày sau khi nhóm đã điền bảng: ")
    add_doc_para(doc, "Kết thúc: “Nhóm em xin cảm ơn thầy cô và các bạn đã theo dõi. Nhóm em xin nhận câu hỏi.”", bold_lead="Kết thúc: ")

    add_doc_heading(doc, "Slide 8  Cảm ơn  khoảng 30 giây", 1)
    add_doc_para(doc,
        "Lời trình bày: “Phần trình bày của nhóm em đến đây là kết thúc. Nhóm em xin chân thành cảm ơn thầy cô và các bạn đã lắng nghe. Nhóm em xin nhận câu hỏi và góp ý.”",
        bold_lead="Lời trình bày: ")

    add_doc_heading(doc, "Cách rút gọn hoặc kéo dài thời gian", 1)
    add_doc_bullet(doc, "Nếu chỉ có 20 phút: rút Doctor còn 1 phút, bỏ DNS config check và chỉ mở cơ chế xác nhận Storage trong 30 giây.")
    add_doc_bullet(doc, "Nếu có 30 phút: giữ đủ các bước, giải thích thêm lệnh xem trước ở DHCP và dành 2–3 phút cho câu hỏi sau kết luận.")
    add_doc_bullet(doc, "Không kéo dài phần giới thiệu. Nếu còn thời gian, ưu tiên giải thích output thật trong demo.")

    doc.save(DOCX_PATH)


if __name__ == "__main__":
    make_deck()
    make_script()
    print(PPTX_PATH)
    print(DOCX_PATH)
