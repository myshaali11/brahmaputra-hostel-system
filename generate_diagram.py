import matplotlib.pyplot as plt
import matplotlib.patches as patches

# Set up figure with 16:9 widescreen ratio, high DPI for presentation
fig, ax = plt.subplots(figsize=(16, 9), dpi=300)
fig.patch.set_facecolor('#FFFFFF')
ax.set_facecolor('#FFFFFF')

# Remove axis lines and ticks
ax.set_xlim(0, 16)
ax.set_ylim(0, 9)
ax.axis('off')

# Color Palette inspired by modern engineering slides
COLOR_AKHILESH = '#DCEEFA'       # Light Blue
BORDER_AKHILESH = '#2563EB'      # Blue
COLOR_MYSHA = '#E6F4EA'          # Light Green
BORDER_MYSHA = '#16A34A'         # Green
COLOR_SHARED = '#FEF3C7'         # Warm Yellow
BORDER_SHARED = '#D97706'        # Amber
COLOR_IO = '#F3F4F6'             # Soft Grey
BORDER_IO = '#6B7280'            # Slate Grey
COLOR_CONTAINER = '#F8FAFC'      # Off-white
BORDER_CONTAINER = '#1E3A8A'      # Deep Navy

# 1. Header
ax.text(0.5, 8.55, "Brahmaputra — system architecture and data flow", 
        fontsize=18, fontweight='bold', color='#0F172A', fontfamily='sans-serif')
ax.text(0.5, 8.25, "CS5013 mid-evaluation — Akhilesh, Mysha Ali — github.com/myshaali11/brahmaputra-hostel-system", 
        fontsize=10.5, color='#475569', fontfamily='sans-serif')

def draw_card(ax, x, y, w, h, bg_color, border_color, title, subtitle_lines, out_text="", title_color='#0F172A'):
    # Rounded card background
    box = patches.FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.03,rounding_size=0.1",
                                facecolor=bg_color, edgecolor=border_color, linewidth=1.5, zorder=2)
    ax.add_patch(box)
    
    # Title
    ax.text(x + 0.12, y + h - 0.28, title, fontsize=10, fontweight='bold', color=title_color, fontfamily='sans-serif', zorder=3)
    
    # Subtitle / content lines
    curr_y = y + h - 0.52
    for line in subtitle_lines:
        ax.text(x + 0.12, curr_y, line, fontsize=8, color='#334155', fontfamily='sans-serif', zorder=3)
        curr_y -= 0.21
        
    # Output tag at bottom if present
    if out_text:
        ax.text(x + 0.12, y + 0.14, out_text, fontsize=7.5, fontstyle='italic', color='#475569', fontfamily='sans-serif', zorder=3)

# 2. Top Row: Input, Web UI, REST API, CLI
# Input Card
draw_card(ax, 0.5, 6.4, 2.7, 1.4, COLOR_IO, BORDER_IO, 
          "Input", 
          ["• Excel dataset (146 boys)", "• Smail IDs (@smail.iitm.ac.in)", "• Student & Staff HTTP requests", "• Google OAuth tokens"],
          title_color='#1E293B')

# Web UI Card (Shared)
draw_card(ax, 3.8, 6.4, 3.2, 1.4, COLOR_SHARED, BORDER_SHARED,
          "Web UI (brahmaputra-frontend)",
          ["• Flutter 3.x + Material 3 (Web/Desktop)", "• Smail Google OAuth Dialog", "• Student, Staff & Manager Dashboards", "• Real-time ticket tracking & inspections"],
          title_color='#92400E')

# REST API Card (Shared)
draw_card(ax, 7.7, 6.4, 3.2, 1.4, COLOR_SHARED, BORDER_SHARED,
          "REST API (brahmaputra-backend)",
          ["• Spring Boot 3.4.3 + Java 21", "• JWT Bearer Auth & Token Bucket Filter", "• OpenAPI 3.0 / Swagger UI", "• CRUD endpoints for tickets & assets"],
          title_color='#92400E')

# CLI / Data Engine (Shared)
draw_card(ax, 11.6, 6.4, 3.9, 1.4, COLOR_SHARED, BORDER_SHARED,
          "CLI / Ingestion (same JAR)",
          ["• Apache POI Excel Streaming Parser", "• Seed DB on startup: zero-config demo", "• Verification test suite (Unit & MockMvc)", "• Direct standalone execution capability"],
          title_color='#92400E')

# Arrows in Top Row
arrow_kw = dict(arrowstyle="->", color="#64748B", lw=1.5, mutation_scale=12)
ax.annotate("", xy=(3.75, 7.1), xytext=(3.25, 7.1), arrowprops=arrow_kw, zorder=4)
ax.annotate("", xy=(7.65, 7.1), xytext=(7.05, 7.1), arrowprops=arrow_kw, zorder=4)
ax.text(7.22, 7.22, "HTTP", fontsize=7.5, fontstyle='italic', color='#64748B', ha='center')
ax.annotate("", xy=(11.55, 7.1), xytext=(10.95, 7.1), arrowprops=arrow_kw, zorder=4)

# 3. Main Engine Outer Container
engine_box = patches.FancyBboxPatch((0.5, 1.25), 15.0, 4.8, boxstyle="round,pad=0.04,rounding_size=0.15",
                                    facecolor=COLOR_CONTAINER, edgecolor=BORDER_CONTAINER, linewidth=2.0, zorder=1)
ax.add_patch(engine_box)

ax.text(0.7, 5.75, "brahmaputra-core — hostel service engine (Spring Boot 3 + JPA: stateless, deterministic, transaction-scoped)",
        fontsize=11.5, fontweight='bold', color='#1E3A8A', fontfamily='sans-serif', zorder=2)
ax.text(0.7, 5.5, "LifecyclePipeline: Excel/OAuth -> RateLimit -> JWT -> Role RBAC -> IVRS Workflow -> KPI Engine",
        fontsize=8.5, color='#475569', fontfamily='sans-serif', zorder=2)

# Connector from top to core engine
ax.annotate("", xy=(8.0, 5.85), xytext=(8.0, 6.35), arrowprops=dict(arrowstyle="->", color="#1E3A8A", lw=1.5), zorder=4)
ax.text(8.05, 6.05, "LifecyclePipeline", fontsize=7.5, fontstyle='italic', color='#1E3A8A')

# 4. Core Pipeline Stages (Row 1: Stages 1-4 by Akhilesh)
w_stage = 2.7
h_stage = 1.7
y_row1 = 3.5

# Stage 1: Ingest & Parse
draw_card(ax, 0.8, y_row1, w_stage, h_stage, COLOR_AKHILESH, BORDER_AKHILESH,
          "1 Ingest & Parse",
          ["• Apache POI streaming", "• Extracts roll no, name, room", "• Links 146 students to floors", "• Handles formatting faults"],
          out_text="out: RosterEntity", title_color='#1E40AF')

# Stage 2: Classify & Validate
draw_card(ax, 3.8, y_row1, w_stage, h_stage, COLOR_AKHILESH, BORDER_AKHILESH,
          "2 Classify & Validate",
          ["• Regex: ^[a-zA-Z]{2}\\d{2}[a-zA-Z]...", "• Smail check (@smail.iitm.ac.in)", "• Dynamic student role assignment", "• Manager / Staff keyword rules"],
          out_text="out: ClassifiedUser", title_color='#1E40AF')

# Stage 3: Rate Limit & Protect
draw_card(ax, 6.8, y_row1, w_stage, h_stage, COLOR_AKHILESH, BORDER_AKHILESH,
          "3 Rate Limit & Protect",
          ["• Bucket4j Token Bucket filter", "• 10 requests / min per IP", "• Rejects with 429 Too Many Req", "• Protects BCrypt from DoS"],
          out_text="out: SanitizedRequest", title_color='#1E40AF')

# Stage 4: Auth & Tokenize
draw_card(ax, 9.8, y_row1, w_stage, h_stage, COLOR_AKHILESH, BORDER_AKHILESH,
          "4 Auth & Tokenize",
          ["• BCrypt verification (2^10 rounds)", "• HMAC-SHA256 JWT generation", "• Claims: sub, roles, roomId", "• Ephemeral token refresh"],
          out_text="out: JwtTokenResponse", title_color='#1E40AF')

# Row 1 Arrows
ax.annotate("", xy=(3.75, y_row1 + h_stage/2), xytext=(3.55, y_row1 + h_stage/2), arrowprops=arrow_kw, zorder=4)
ax.annotate("", xy=(6.75, y_row1 + h_stage/2), xytext=(6.55, y_row1 + h_stage/2), arrowprops=arrow_kw, zorder=4)
ax.annotate("", xy=(9.75, y_row1 + h_stage/2), xytext=(9.55, y_row1 + h_stage/2), arrowprops=arrow_kw, zorder=4)

# 5. Core Pipeline Stages (Row 2: Stages 5-8 by Mysha Ali + Output)
y_row2 = 1.5

# Stage 5: Authorize & Route
draw_card(ax, 0.8, y_row2, w_stage, h_stage, COLOR_MYSHA, BORDER_MYSHA,
          "5 Authorize & Route",
          ["• Spring Security filter chain", "• Method-level @PreAuthorize", "• Student / Staff isolation", "• Room-scoped complaint guard"],
          out_text="out: SecurityContext", title_color='#166534')

# Stage 6: Ticket Lifecycle
draw_card(ax, 3.8, y_row2, w_stage, h_stage, COLOR_MYSHA, BORDER_MYSHA,
          "6 Ticket Lifecycle",
          ["• IVRS code generator: TICK-XXXX", "• Priority: LOW, MED, HIGH, URG", "• State Machine: OPEN ->", "  IN_PROGRESS -> RESOLVED"],
          out_text="out: ComplaintEntity", title_color='#166534')

# Stage 7: Audit & Inspect
draw_card(ax, 6.8, y_row2, w_stage, h_stage, COLOR_MYSHA, BORDER_MYSHA,
          "7 Audit & Inspect",
          ["• Staff inspection timestamping", "• Maintenance note logging", "• Room fixture state mutations", "• Eliminates stale complaints"],
          out_text="out: InspectionLog", title_color='#166534')

# Stage 8: Executive KPI
draw_card(ax, 9.8, y_row2, w_stage, h_stage, COLOR_MYSHA, BORDER_MYSHA,
          "8 Executive KPI Engine",
          ["• Aggregate analytics computation", "• Floor-wise occupancy tracking", "• High-priority ticket counts", "• Manager resolution summaries"],
          out_text="out: DashboardSummary", title_color='#166534')

# Row 2 Arrows
ax.annotate("", xy=(3.75, y_row2 + h_stage/2), xytext=(3.55, y_row2 + h_stage/2), arrowprops=arrow_kw, zorder=4)
ax.annotate("", xy=(6.75, y_row2 + h_stage/2), xytext=(6.55, y_row2 + h_stage/2), arrowprops=arrow_kw, zorder=4)
ax.annotate("", xy=(9.75, y_row2 + h_stage/2), xytext=(9.55, y_row2 + h_stage/2), arrowprops=arrow_kw, zorder=4)

# Connector from Stage 4 to Stage 5
ax.annotate("", xy=(1.0, y_row1 - 0.05), xytext=(11.15, y_row1 + 0.1),
            arrowprops=dict(arrowstyle="->", color="#64748B", lw=1.2, connectionstyle="arc3,rad=-0.15"), zorder=4)

# Output Card inside Core (Far Right)
draw_card(ax, 12.8, 1.5, 2.5, 3.7, COLOR_IO, BORDER_IO,
          "Output",
          ["• Real-time REST Responses", 
           "• Swagger UI Interactive Spec", 
           "• Flutter Dynamic Dashboards",
           "• In-Memory H2 DB / Audit Trail",
           "• IVRS Resolution Receipts",
           "• 0-Config Demo Ready"],
          out_text="System Verified: 100% Tests Pass", title_color='#1E293B')

# Arrow from Stage 8 to Output
ax.annotate("", xy=(12.75, y_row2 + h_stage/2), xytext=(12.55, y_row2 + h_stage/2), arrowprops=arrow_kw, zorder=4)

# 6. Footer / Legend
def draw_legend_box(ax, x, y, color, border, label):
    box = patches.Rectangle((x, y), 0.35, 0.22, facecolor=color, edgecolor=border, linewidth=1.2)
    ax.add_patch(box)
    ax.text(x + 0.45, y + 0.04, label, fontsize=8.5, color='#1E293B', fontfamily='sans-serif')

draw_legend_box(ax, 0.6, 0.65, COLOR_AKHILESH, BORDER_AKHILESH, "Akhilesh — Stages 1-4 (Ingestion, OAuth Classification, Rate Limiting & Auth Engine)")
draw_legend_box(ax, 6.2, 0.65, COLOR_MYSHA, BORDER_MYSHA, "Mysha Ali — Stages 5-8 (RBAC, Ticket State Machine, Inspections & Executive KPI)")
draw_legend_box(ax, 12.0, 0.65, COLOR_SHARED, BORDER_SHARED, "Shared — Spring Boot API, Flutter UI, Swagger")
draw_legend_box(ax, 14.5, 0.65, COLOR_IO, BORDER_IO, "Input / Output")

ax.text(0.6, 0.28, "Security Rule: Bucket4j protects BCrypt from CPU exhaustion. Smail regex automatically classifies 146 students and staff. Tests: 100% pass (Spring Boot + Flutter).",
        fontsize=8, color='#64748B', fontfamily='sans-serif')

plt.tight_layout()
plt.savefig(r"D:\IITM\PAI\PAI_project\project_repo\brahmaputra_mid_evaluation_architecture.png", dpi=300, bbox_inches='tight')
plt.savefig(r"D:\IITM\PAI\PAI_project\brahmaputra_mid_evaluation_architecture.png", dpi=300, bbox_inches='tight')
print("Saved architecture diagrams successfully!")
