import json
import os
import csv

# Define the input and output file paths
input_filename = '/Users/henrygroman/development/python-projects/3rd-Party-Expenses/mac_app_inventory_MacBook-Pro.json'
output_md_filename = '/Users/henrygroman/development/python-projects/n8n/My_Mac_Apps.md'
output_csv_filename = '/Users/henrygroman/development/python-projects/n8n/My_Mac_Apps.csv'

# Define categories and associated keywords (case-insensitive)
# This list is intentionally broad to catch variations.
CATEGORIES = {
    'Development & Engineering': ['xcode', 'visual studio code', 'iterm', 'docker', 'python', 'git', 'sublime', 'postman', 'hex fiend', 'script', 'android studio', 'pycharm', 'goland', 'webstorm', 'cursor', 'terminus', 'shuttle', 'anaconda', 'qml', 'qdbusviewer'],
    'Cloud & Infrastructure': ['aws', 'google cloud', 'cloudflare warp', 'tailscale', 'backblaze', 'google drive'],
    'Database Tools': ['tableplus', 'db browser for sqlite', 'postico'],
    'Design & Media': ['figma', 'photoshop', 'illustrator', 'premiere', 'after effects', 'final cut pro', 'logic pro', 'screenflow', 'imageoptim', 'affinity', 'canva', 'handbrake', 'vlc', 'iina', 'xscope', 'obs', 'garageband', 'imovie', 'adobe bridge', 'lightroom', 'camera', 'color picker', 'elgato stream deck', 'reaktor', 'kontakt', 'guitar rig', 'massive', 'fm8', 'battery 4', 'scream', 'audible', 'spotify', 'muse hub', 'sinee player', 'spitfire audio'],
    'Productivity & Collaboration': ['slack', 'notion', 'things', 'obsidian', 'trello', 'asana', 'microsoft word', 'excel', 'powerpoint', 'keynote', 'pages', 'numbers', 'zoom', 'loom', 'cleanshot', 'raycast', 'alfred', '1password', 'grammarly', 'todoist', 'bitwarden', 'claude', 'perplexity', 'windsurf', 'dart', 'messenger', 'whatsapp', 'microsoft teams', 'microsoft onenote', 'microsoft outlook', 'fathom', 'gPlayer-Mac', 'memserverui', 'voices'],
    'Web Browsers': ['safari', 'google chrome', 'firefox', 'arc', 'brave browser', 'microsoft edge'],
    'System & Utilities': ['appcleaner', 'unarchiver', 'bartender', 'istat menus', 'karabiner', 'rectangle', 'alt-tab', 'commander one', 'ccleaner', 'cleanmymac', 'dropover', 'logi options+', 'remotePC', 'imazing', 'ilok license manager', 'brother scanner', 'vienna assistant', 'vienna ensemble', 'vienna synchron player', 'pulsewayagent', 'localscraper', 'macwhisper', 'windows app'],
    'Other': []
}

# Define keywords for apps/processes to completely ignore (case-insensitive)
IGNORE_KEYWORDS = [
    # General Junk
    'helper', 'updater', 'agent', 'service', 'daemon', 'broker', 'installer', 'uninstaller', 'uninstall ',
    'crash', 'diagnostics', 'licensing', 'mobiledevice', 'mobilesync', 'firmware', 'plugin',
    'hostintegration', 'transport', 'com.apple.', 'com.lemonmojo.', 'group.ai', 'group.is.workflow',
    'setup', 'droplet', 'ni-plugin-info', 'vslhelper', 'ntkdaemon', 'uninstallbackblaze', 'mrt',
    'applet', 'qdbusviewer', 'qml', 'memserverui', 'utility', 'monitor', 'troubleshooter',
    'editor', 'content manager', 'beta', 'rpc', 'transfer', 'view', 'control', 'opener',
    'airscanlegacydiscovery', 'phspbeta', 'xprotect', 'adsr sample manager', 'antares central',
    'comet', 'creator tools', 'gumroad', 'native access', 'gplayer-mac', 'core sync', 'install',

    # Adobe Junk
    'adobeipc', 'adobegcclient', 'cclibrary', 'coresync', 'ccxp', 'acrotray', 'adobe update',
    'adobe crash', 'adobe desktop', 'adobecreativecloud', 'adobelightroom', 'adobecleanup',
    'logi', 'cops_', 'core_', 'corg_', 'cosy_', 'phsp_', 'ppro_', 'ame_', 'kbrg_', 'lrcc_',
    'ltrm_', 'seps_', 'comp_', 'cocm_', 'libs_', 'acr_',

    # Other Vendor Junk
    'googleupdater', 'dropboxmacupdate', 'edgeupdater', 'bzbmenu', 'microsoft autoupdate',
    'remotepc', 'filetransfer', 'uninstall ozone', 'uninstall product', 'uninstall resolve',
    'uninstall trash', 'uninstall vinyl', 'uninstall vocalsynth', 'uninstall vienna'
]

# Define the desired order for categories
CATEGORY_ORDER = [
    'Development & Engineering',
    'Cloud & Infrastructure',
    'Database Tools',
    'Design & Media',
    'Productivity & Collaboration',
    'Web Browsers',
    'System & Utilities',
    'Apple System Apps',
    'Other'
]

def get_category(app_name):
    app_name_lower = app_name.lower()
    for category, keywords in CATEGORIES.items():
        for keyword in keywords:
            if keyword in app_name_lower:
                return category
    return 'Other'

def process_inventory():
    # Check if the input file exists
    if not os.path.exists(input_filename):
        print(f"Error: Input file not found at {input_filename}")
        return

    # Read the verbose JSON data
    with open(input_filename, 'r') as f:
        data = json.load(f)

    # Initialize the categorized dictionary with the desired order
    categorized_apps = {category: [] for category in CATEGORY_ORDER}

    # Process each application
    for app in data.get('applications', []):
        path = app.get('path', '')
        app_name = app.get('_name', 'Unknown')
        app_name_lower = app_name.lower()

        # --- AGGRESSIVE FILTERING ---
        # 1. Ignore system applications by path
        if path.startswith('/System/'):
            continue

        # 2. Ignore based on keywords in the name
        if any(keyword in app_name_lower for keyword in IGNORE_KEYWORDS):
            continue
        # --- END FILTERING ---

        version = app.get('version', 'N/A')
        category = get_category(app_name)
        
        # Avoid duplicates (case-insensitive)
        if not any(d['name'].lower() == app_name.lower() for d in categorized_apps[category]):
            categorized_apps[category].append({
                'name': app_name,
                'version': version
            })

    # Sort apps alphabetically within each category
    for category in categorized_apps:
        categorized_apps[category].sort(key=lambda x: x['name'].lower())

    # --- Write Markdown File ---
    try:
        with open(output_md_filename, 'w', encoding='utf-8') as f:
            f.write(f"# Application Inventory for {data.get('machine', 'N/A')}\n")
            f.write(f"_Generated on {data.get('generated', 'N/A')}_\n\n")

            for category in CATEGORY_ORDER:
                apps_in_category = categorized_apps[category]
                if apps_in_category:
                    f.write(f"## {category}\n\n")
                    for app in apps_in_category:
                        f.write(f"- **{app['name']}** (Version: {app['version']})\n")
                    f.write('\n')

            print(f"Successfully processed inventory. Cleaned data written to {output_md_filename}")
    except IOError as e:
        print(f"Error writing to file {output_md_filename}: {e}")

    # --- Write CSV File ---
    try:
        with open(output_csv_filename, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            # Write header
            writer.writerow(['Category', 'Application Name', 'Version', 'Cost Model (Free/Paid)'])
            
            # Write data rows
            for category in CATEGORY_ORDER:
                if category in categorized_apps and categorized_apps[category]:
                    for app in categorized_apps[category]:
                        writer.writerow([category, app['name'], app['version'], ''])
        print(f"Successfully created CSV inventory at {output_csv_filename}")
    except IOError as e:
        print(f"Error writing to CSV file {output_csv_filename}: {e}")

if __name__ == '__main__':
    process_inventory()
