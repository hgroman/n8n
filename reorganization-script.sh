#!/bin/bash

# Project Reorganization Script for n8n Repository
# Date: 2025-11-25
# Purpose: Safely reorganize project structure while preserving git history

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Function to confirm action
confirm() {
    read -p "$(echo -e ${YELLOW}$1${NC}) [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Main script starts here
log_info "n8n Project Reorganization Script"
echo "======================================"
echo ""

# Check if we're in the right directory
if [ ! -f "README.md" ] || [ ! -d "n8n-Workflows" ]; then
    log_error "This script must be run from the n8n repository root"
    exit 1
fi

log_success "Detected n8n repository"
echo ""

# Safety check
log_warning "This script will reorganize your repository structure."
log_warning "Please ensure you have:"
log_warning "  1. Committed all current changes"
log_warning "  2. Created a backup"
log_warning "  3. Reviewed the reorganization proposal"
echo ""

if ! confirm "Continue with reorganization?"; then
    log_info "Reorganization cancelled."
    exit 0
fi

# Create backup branch
log_info "Creating backup branch..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_BRANCH="backup/before-reorg-${TIMESTAMP}"
git branch "${BACKUP_BRANCH}"
log_success "Backup branch created: ${BACKUP_BRANCH}"
echo ""

# Phase 1: Create new directory structure
log_info "Phase 1: Creating new directory structure..."
echo ""

# Create main directories
mkdir -p docs/{setup,workflows,troubleshooting,project-history/{preparation,implementation},architecture,reference}
mkdir -p workflows/{production,archive,templates}
mkdir -p deployment/{local,windows/cloudflared,production}
mkdir -p scripts/{backup,deployment,utils}
mkdir -p prompts
mkdir -p templates/{email-templates/ses-templates,report-templates}
mkdir -p archive/{planning,reports,personas,misc}
mkdir -p .github/{workflows,ISSUE_TEMPLATE}
mkdir -p assets/workflow-screenshots

log_success "Directory structure created"
echo ""

# Phase 2: Move workflow files (highest priority)
log_info "Phase 2: Reorganizing workflows..."
echo ""

# Production workflows
git mv "n8n-Workflows/n8n_CROWS_NEST_07.23.25-3.json" "workflows/production/CROWS-NEST-v1.0.json"
git mv "n8n-Workflows/HubSpot to AWS SES.json" "workflows/production/HubSpot-SES-v1.0.json"
git mv "n8n-Workflows/HubSpot - Strategic Outreach Monitor.json" "workflows/production/HubSpot-Outreach-Monitor-v1.0.json"
git mv "n8n-Workflows/Life Architect.json" "workflows/production/Life-Architect-v1.0.json"

# Archive old workflow iterations
git mv "n8n-Workflows/friendly-competitor-spy.json" "workflows/archive/competitor-spy-v0.1.json"
git mv "n8n-Workflows/friendly-competitor-spy-2.json" "workflows/archive/competitor-spy-v0.2.json"
git mv "n8n-Workflows/friendly-competitor-spy-3.json" "workflows/archive/competitor-spy-v0.3.json"
git mv "n8n-Workflows/friendly-competitor-spy-4.json" "workflows/archive/competitor-spy-v0.4.json"
git mv "n8n-Workflows/friendly-competitor-spy 07.17.25.json" "workflows/archive/competitor-spy-v0.5-dated.json"

# Remove empty workflow directory
rmdir "n8n-Workflows"

log_success "Workflows reorganized"
echo ""

# Phase 3: Move documentation
log_info "Phase 3: Reorganizing documentation..."
echo ""

# Move your new setup guide to proper location
git mv "Docs/SETUP_GUIDE_CROWS_NEST.md" "docs/setup/CROWS-NEST-Setup.md"

# Move project history
git mv "Docs/00_Project_n8n_The_Complete_Journey.md" "docs/project-history/00-Project-Journey.md"

# Move preparation docs
git mv "Docs/Project_Preparation/1-hardware_infrastructure.md" "docs/project-history/preparation/01-Hardware-Infrastructure.md"
git mv "Docs/Project_Preparation/2-software_environment.md" "docs/project-history/preparation/02-Software-Environment.md"
git mv "Docs/Project_Preparation/3-network_configuration.md" "docs/project-history/preparation/03-Network-Configuration.md"
git mv "Docs/Project_Preparation/4-hubspot_integration.md" "docs/project-history/preparation/04-HubSpot-Integration.md"
git mv "Docs/Project_Preparation/5-workflow_definitions.md" "docs/project-history/preparation/05-Workflow-Definitions.md"
git mv "Docs/Project_Preparation/6-technical_requirements.md" "docs/project-history/preparation/06-Technical-Requirements.md"
git mv "Docs/Project_Preparation/7-implementation_plan.md" "docs/project-history/preparation/07-Implementation-Plan.md"
git mv "Docs/Project_Preparation/8-knowledge_base.md" "docs/project-history/preparation/08-Knowledge-Base.md"

# Move implementation docs
git mv "Docs/Project_Implementation/01_Project_Vision_and_Blueprint_(CLINE).md" "docs/project-history/implementation/01-Project-Vision-Blueprint-CLINE.md"
git mv "Docs/Project_Implementation/02_Initial_Infrastructure_Setup_Guide_(CLINE).md" "docs/project-history/implementation/02-Infrastructure-Setup-CLINE.md"
git mv "Docs/Project_Implementation/03_Troubleshooting_Cloudflare_Tunnel_Fix_(Windsurf).md" "docs/troubleshooting/Cloudflare-Tunnel.md"
git mv "Docs/Project_Implementation/04_Final_Master_Setup_Guide_with_Google_OAuth_(Windsurf).md" "docs/project-history/implementation/04-Google-OAuth-Setup-Windsurf.md"
git mv "Docs/Project_Implementation/05_AWS_SES_Cleanup_and_Consolidation_(Windsurf).md" "docs/project-history/implementation/05-AWS-SES-Consolidation-Windsurf.md"
git mv "Docs/Project_Implementation/06_HubSpot_SES_Integration_Playbook_(Windsurf).md" "docs/workflows/HubSpot-SES-Integration.md"

# Move reorganization proposal
git mv "Docs/PROJECT_REORGANIZATION_PROPOSAL.md" "docs/PROJECT-REORGANIZATION-PROPOSAL.md"

# Remove empty old doc directories
rmdir "Docs/Project_Preparation"
rmdir "Docs/Project_Implementation"
rmdir "Docs"

log_success "Documentation reorganized"
echo ""

# Phase 4: Move deployment configurations
log_info "Phase 4: Reorganizing deployment configs..."
echo ""

# Local deployment
git mv "n8n-local/docker-compose.yml" "deployment/local/docker-compose.yml"
git mv "n8n-local/backup.sh" "deployment/local/backup.sh"
rmdir "n8n-local"

# Windows deployment
git mv "windows-deployment/docker-compose.yml" "deployment/windows/docker-compose.yml"
git mv "windows-deployment/.env.example" "deployment/windows/.env.example"
git mv "windows-deployment/deploy.ps1" "deployment/windows/deploy.ps1"
git mv "windows-deployment/backup.ps1" "deployment/windows/backup.ps1"
git mv "windows-deployment/install-service.ps1" "deployment/windows/install-service.ps1"
git mv "windows-deployment/cloudflared/config.yml" "deployment/windows/cloudflared/config.yml"
git mv "windows-deployment/Knowledge Base/ChatGPT input.md" "deployment/windows/knowledge-base/chatgpt-input.md"
git mv "windows-deployment/Knowledge Base/Claude input.md" "deployment/windows/knowledge-base/claude-input.md"
git mv "windows-deployment/Knowledge Base/Grok input.md" "deployment/windows/knowledge-base/grok-input.md"
git mv "windows-deployment/MIGRATION_CHECKLIST.md" "deployment/windows/MIGRATION-CHECKLIST.md"
git mv "windows-deployment/README.md" "deployment/windows/README.md"

# Remove empty windows deployment directories
rmdir "windows-deployment/Knowledge Base"
rmdir "windows-deployment/cloudflared"
rmdir "windows-deployment"

log_success "Deployment configs reorganized"
echo ""

# Phase 5: Move archive content
log_info "Phase 5: Archiving old content..."
echo ""

# Planning documents
git mv "Grok Plan Draft 1.md" "archive/planning/grok-plan-draft-1.md"
git mv "Grok Plan Draft 2.md" "archive/planning/grok-plan-draft-2.md"
git mv "Grok Plan Draft 3.md" "archive/planning/grok-plan-draft-3.md"
git mv "Grok Plan Draft 4.md" "archive/planning/grok-plan-draft-4.md"

# State of nation reports
git mv "State of the Nation - ChatGPT.md" "archive/reports/state-of-nation-chatgpt.md"
git mv "State of the Nation - Claude Part1.md" "archive/reports/state-of-nation-claude-part1.md"
git mv "State of the Nation - Claude Part2.md" "archive/reports/state-of-nation-claude-part2.md"
git mv "State of the Nation - Gemini.md" "archive/reports/state-of-nation-gemini.md"
git mv "State of the Nation - Grok.md" "archive/reports/state-of-nation-grok.md"
git mv "State of the Nation - Strategic Synthesis.md" "archive/reports/state-of-nation-synthesis.md"

# Personas
git mv "Personas/fifth_beatle_persona.md" "archive/personas/fifth-beatle-persona.md"
git mv "Personas/n8n_Persona_The_Fifth_Beatle_v1.1.md" "archive/personas/fifth-beatle-v1.1.md"
rmdir "Personas"

# Miscellaneous files
git mv "1.md" "archive/misc/1.md"
git mv "2.md" "archive/misc/2.md"
git mv "3.md" "archive/misc/3.md"
git mv "My_Mac_Apps.csv" "archive/misc/my-mac-apps.csv"
git mv "My_Mac_Apps.md" "archive/misc/my-mac-apps.md"
git mv "WORK_ORDER_Windows_Production_Deployment.md" "deployment/windows/WORK-ORDER.md"

log_success "Content archived"
echo ""

# Phase 6: Move scripts
log_info "Phase 6: Organizing scripts..."
echo ""

git mv "process_inventory.py" "scripts/utils/process-inventory.py"

log_success "Scripts organized"
echo ""

# Phase 7: Handle HTML templates
log_info "Phase 7: Moving templates..."
echo ""

if [ -d "html" ]; then
    git mv "html/template.html" "templates/email-templates/template.html"
    rmdir "html"
    log_success "Templates moved"
else
    log_warning "HTML directory not found, skipping"
fi
echo ""

# Phase 8: Create README files for new directories
log_info "Phase 8: Creating README files..."
echo ""

# Workflow archive README
cat > workflows/archive/README.md << 'EOF'
# Archived Workflows

This directory contains deprecated workflow versions kept for historical reference.

## Version History

- **competitor-spy-v0.1.json** - Original friendly-competitor-spy implementation
- **competitor-spy-v0.2.json** - Second iteration with improvements
- **competitor-spy-v0.3.json** - Third iteration with bug fixes
- **competitor-spy-v0.4.json** - Fourth iteration with enhanced parsing
- **competitor-spy-v0.5-dated.json** - Dated version from 07.17.25

**Latest Version:** See `workflows/production/CROWS-NEST-v1.0.json`

## Do Not Use

These workflows are kept for reference only. Do not import them for production use.
EOF

# Archive README
cat > archive/README.md << 'EOF'
# Archive

This directory contains historical content that is no longer actively used but preserved for reference.

## Structure

- **planning/** - Early project planning documents from various AI assistants
- **reports/** - "State of the Nation" analysis reports
- **personas/** - AI persona definitions used during development
- **misc/** - Miscellaneous files not directly related to n8n

## Why Archived?

These files represent the evolution of the project but are not needed for current operations or setup.
EOF

git add workflows/archive/README.md
git add archive/README.md

log_success "README files created"
echo ""

# Final summary
echo ""
echo "======================================"
log_success "Reorganization complete!"
echo "======================================"
echo ""
log_info "Summary of changes:"
echo "  - Created new directory structure"
echo "  - Reorganized workflows with semantic versioning"
echo "  - Consolidated documentation"
echo "  - Moved deployment configurations"
echo "  - Archived old content"
echo ""
log_info "Backup branch: ${BACKUP_BRANCH}"
log_warning "Git history preserved for all moved files"
echo ""
log_info "Next steps:"
echo "  1. Review changes: git status"
echo "  2. Update README.md with new structure"
echo "  3. Create QUICKSTART.md"
echo "  4. Test deployment configurations"
echo "  5. Commit changes: git commit -m 'Reorganize project structure'"
echo ""
log_warning "To revert: git reset --hard ${BACKUP_BRANCH}"
echo ""
