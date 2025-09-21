import gradio as gr
import json
import requests
import os
import matplotlib.pyplot as plt
import numpy as np

# --- IMPORTANT ---
# Paste your Google Gemini API key here.
# You can get one from Google AI Studio: https://aistudio.google.com/app/apikey
API_KEY = os.environ.get("GEMINI_API_KEY", "")

# --- Example Data ---
DEFAULT_BUILDINGS_A_JSON = """
[
  {
    "name": "Town Hall",
    "type": "civic",
    "cost": 12000,
    "location": {"x": 50, "y": 50}
  },
  {
    "name": "Struggling Farm Plot",
    "type": "farmland",
    "cost": 3000,
    "location": {"x": 20, "y": 30}
  },
  {
    "name": "Dried Up Well",
    "type": "utility",
    "cost": 500,
    "location": {"x": 45, "y": 25},
    "notes": "No longer provides water."
  },
  {
    "name": "Water Hauling Post",
    "type": "utility",
    "cost": 2500,
    "location": {"x": 70, "y": 15},
    "notes": "Labor-intensive water transport."
  },
  {
    "name": "Blacksmith",
    "type": "commercial",
    "cost": 6000,
    "location": {"x": 55, "y": 40}
  },
  {
    "name": "Basic Huts",
    "type": "housing",
    "cost": 3000,
    "location": {"x": 40, "y": 60}
  },
  {
    "name": "Deep Well Project",
    "type": "project",
    "cost": 15000,
    "location": {"x": 80, "y": 80},
    "notes": "Attempt to find new water source."
  }
]
"""

DEFAULT_BUILDINGS_B_JSON = """
[
  {
    "name": "Grand Hall",
    "type": "civic",
    "cost": 18000,
    "location": {"x": 50, "y": 50}
  },
  {
    "name": "Lush Farmland A",
    "type": "farmland",
    "cost": 4000,
    "location": {"x": 10, "y": 20}
  },
    {
    "name": "Lush Farmland B",
    "type": "farmland",
    "cost": 4000,
    "location": {"x": 20, "y": 80}
  },
  {
    "name": "Central Fountain",
    "type": "utility",
    "cost": 5000,
    "location": {"x": 45, "y": 45},
    "notes": "Abundant clean water."
  },
  {
    "name": "Bustling Marketplace",
    "type": "commercial",
    "cost": 10000,
    "location": {"x": 40, "y": 60}
  },
  {
    "name": "Stone Houses",
    "type": "housing",
    "cost": 12000,
    "location": {"x": 70, "y": 70}
  },
  {
    "name": "Irrigation Canals",
    "type": "utility",
    "cost": 8000,
    "location": {"x": 15, "y": 50},
    "notes": "Distributes water to farms."
  }
]
"""

def create_village_plot(buildings_data, title):
    """Creates a scatter plot visualization of the village layout."""
    plt.style.use('seaborn-v0_8-whitegrid')
    fig, ax = plt.subplots(figsize=(8, 8))

    try:
        buildings = json.loads(buildings_data)
        if not isinstance(buildings, list):
            raise ValueError("JSON data must be a list of buildings.")
    except Exception as e:
        ax.text(0.5, 0.5, f"Error parsing JSON:\n{e}", ha='center', va='center')
        ax.set_title(title)
        return fig

    locations = [b for b in buildings if 'location' in b and 'x' in b['location'] and 'y' in b['location']]

    if not locations:
        ax.text(0.5, 0.5, "No location data found in JSON.", ha='center', va='center')
        ax.set_title(title)
        return fig

    # Define a color map for building types
    unique_types = sorted(list(set(b.get('type', 'unknown') for b in locations)))
    colors = plt.cm.get_cmap('viridis', len(unique_types))
    type_color_map = {b_type: colors(i) for i, b_type in enumerate(unique_types)}
    type_color_map['unknown'] = 'grey'


    for b_type in unique_types:
        xs = [b['location']['x'] for b in locations if b.get('type', 'unknown') == b_type]
        ys = [b['location']['y'] for b in locations if b.get('type', 'unknown') == b_type]
        ax.scatter(xs, ys, label=b_type.title(), color=type_color_map[b_type], s=100, alpha=0.7, edgecolors='w')

    for b in locations:
        ax.text(b['location']['x'], b['location']['y'] + 2, b.get('name', ''), fontsize=9, ha='center')

    ax.set_title(title, fontsize=16)
    ax.set_xlabel("X Coordinate")
    ax.set_ylabel("Y Coordinate")
    ax.legend(title="Building Types")
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 100)
    ax.grid(True)

    return fig


def calculate_stats(buildings_data, budget):
    """Calculates detailed statistics for a single village."""
    stats = {
        'total_cost': 0,
        'budget_utilization': 0,
        'building_counts': {},
        'cost_by_type': {},
        'error': None
    }
    try:
        buildings = json.loads(buildings_data)
        if not isinstance(buildings, list):
             raise ValueError("JSON data must be a list of buildings.")
    except Exception as e:
        stats['error'] = f"❌ Error parsing buildings data: {e}"
        return stats

    stats['total_cost'] = sum(b.get("cost", 0) for b in buildings)
    if budget > 0:
        stats['budget_utilization'] = round((stats['total_cost'] / budget) * 100, 2)

    for b in buildings:
        b_type = b.get("type", "unknown").strip()
        b_cost = b.get("cost", 0)
        stats['building_counts'][b_type] = stats['building_counts'].get(b_type, 0) + 1
        stats['cost_by_type'][b_type] = stats['cost_by_type'].get(b_type, 0) + b_cost

    return stats

def format_stats_for_display(stats, name, budget):
    """Formats the calculated stats into a Markdown string for display."""
    if stats['error']:
        return stats['error']

    md = f"**Total Cost:** `{stats['total_cost']}`\n\n"
    md += f"**Budget:** `{budget}`\n\n"
    md += f"**Budget Utilization:** `{stats['budget_utilization']}%`\n\n"

    md += "**Building Counts:**\n"
    if not stats['building_counts']:
        md += "- No buildings found.\n"
    else:
        for b_type, count in stats['building_counts'].items():
            md += f"- **{b_type.title()}:** {count}\n"
    md += "\n"

    md += "**Cost by Type:**\n"
    if not stats['cost_by_type']:
        md += "- No costs to show.\n"
    else:
        for b_type, cost in stats['cost_by_type'].items():
            md += f"- **{b_type.title()}:** {cost}\n"

    return md

def compare_villages(buildings_data_A, budget_A, buildings_data_B, budget_B):
    """
    Analyzes and compares two villages, providing stats and Gemini-powered suggestions.
    """
    if API_KEY == "YOUR_GEMINI_API_KEY":
        error_msg = "Please set your Gemini API_KEY in the script (village_optimizer.py) first."
        blank_plot = create_village_plot("[]", "Error")
        return "ERROR", "ERROR", "N/A", error_msg, blank_plot, blank_plot

    stats_A = calculate_stats(buildings_data_A, budget_A)
    stats_B = calculate_stats(buildings_data_B, budget_B)

    plot_A = create_village_plot(buildings_data_A, "Village A Layout")
    plot_B = create_village_plot(buildings_data_B, "Village B Layout")

    stats_A_md = format_stats_for_display(stats_A, "Village A", budget_A)
    stats_B_md = format_stats_for_display(stats_B, "Village B", budget_B)

    if stats_A['error'] or stats_B['error']:
        return stats_A_md, stats_B_md, "N/A", "Please fix the JSON errors before proceeding.", plot_A, plot_B

    # 3️⃣ Ask Gemini for a comparative analysis
    prompt = (
        "You are an expert city planner and resource management strategist for a medieval-style village game.\n"
        "Analyze the following data for two different village layouts, Village A and Village B, and provide a comprehensive comparative analysis.\n\n"
        "--- Village A Data (Experiencing a Water Problem) ---\n"
        f"Budget: {budget_A}\n"
        f"Stats: {json.dumps(stats_A, indent=2)}\n"
        f"Buildings: {buildings_data_A}\n\n"
        "--- Village B Data (Thriving with Abundant Water) ---\n"
        f"Budget: {budget_B}\n"
        f"Stats: {json.dumps(stats_B, indent=2)}\n"
        f"Buildings: {buildings_data_B}\n\n"
        "--- Your Task ---\n"
        "Please provide the following in your analysis, using Markdown for clear formatting:\n"
        "1.  **Overall Score & Winner:** Give each village an optimization score out of 100 based on efficiency, budget use, and layout balance. Briefly justify the scores and declare a 'winner' if one is clearly superior.\n"
        "2.  **Comparative Analysis (Strengths & Weaknesses):** Create a table or bulleted lists comparing the pros and cons of each village's layout, cost distribution, and building choices, paying special attention to the water situation.\n"
        "3.  **Actionable Suggestions:** Provide specific, actionable advice for improving EACH village. For Village A, focus on solving the water crisis. For Village B, suggest ways to leverage its advantages."
    )

    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key={API_KEY}"
    headers = {"Content-Type": "application/json"}
    data = {"contents": [{"parts": [{"text": prompt}]}]}
    suggestions = "Fetching suggestions..."

    try:
        response = requests.post(url, headers=headers, json=data, timeout=20)
        response.raise_for_status()
        resp_json = response.json()
        suggestions = resp_json.get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "No suggestions received.")
    except requests.exceptions.RequestException as e:
        suggestions = f"⚠️ Network or API Error: Could not fetch suggestions. Details: {e}"
    except (KeyError, IndexError) as e:
        suggestions = f"⚠️ Error parsing API response. Raw response: {response.text}"
    except Exception as e:
        suggestions = f"⚠️ An unexpected error occurred: {e}"

    # Calculate a simple overall score for the UI
    avg_utilization = (stats_A.get('budget_utilization', 0) + stats_B.get('budget_utilization', 0)) / 2
    overall_score_label = f"{avg_utilization:.2f}% (Average Budget Utilization)"

    return stats_A_md, stats_B_md, overall_score_label, suggestions, plot_A, plot_B

# --- Gradio Interface ---
with gr.Blocks(theme=gr.themes.Soft()) as demo:
    gr.Markdown("# 🏡 Village Comparator using Gemini API")
    gr.Markdown("Input data for two villages to compare their stats, visualize their layouts, and get AI-powered optimization advice.")

    with gr.Row():
        with gr.Column(scale=2):
            with gr.Tabs():
                with gr.TabItem("Village A (Water Problem)"):
                    buildings_data_A = gr.Code(label="Village A Buildings (JSON)", language="json", lines=15, value=DEFAULT_BUILDINGS_A_JSON)
                    budget_A = gr.Number(label="Village A Budget", value=50000, step=1000)
                with gr.TabItem("Village B (Thriving)"):
                    buildings_data_B = gr.Code(label="Village B Buildings (JSON)", language="json", lines=15, value=DEFAULT_BUILDINGS_B_JSON)
                    budget_B = gr.Number(label="Village B Budget", value=80000, step=1000)
            btn = gr.Button("Compare Village Layouts", variant="primary")

        with gr.Column(scale=3):
            with gr.Row():
                with gr.Column():
                    gr.Markdown("### Village A Stats")
                    stats_output_A = gr.Markdown()
                with gr.Column():
                    gr.Markdown("### Village B Stats")
                    stats_output_B = gr.Markdown()
            overall_score_output = gr.Textbox(label="Overall Score Metric", info="A simple metric for quick comparison.")
            suggestions_output = gr.Markdown(label="💡 Gemini's Comparative Analysis")
    
    with gr.Row():
        with gr.Column():
            plot_output_A = gr.Plot(label="Village A Layout")
        with gr.Column():
            plot_output_B = gr.Plot(label="Village B Layout")


    btn.click(
        fn=compare_villages,
        inputs=[buildings_data_A, budget_A, buildings_data_B, budget_B],
        outputs=[stats_output_A, stats_output_B, overall_score_output, suggestions_output, plot_output_A, plot_output_B]
    )

if __name__ == "__main__":
    demo.launch()

