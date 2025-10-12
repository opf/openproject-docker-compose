#!/bin/bash
# Simple dependency checker and installer for OpenProject Docker Compose

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐳 OpenProject Docker Compose - Dependency Checker${NC}"
echo "=================================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Docker
check_docker() {
    echo -n "Checking Docker... "
    if command_exists docker; then
        echo -e "${GREEN}✓ Found${NC}"
        docker --version
        return 0
    else
        echo -e "${RED}✗ Missing${NC}"
        return 1
    fi
}

# Function to check Docker Compose
check_docker_compose() {
    echo -n "Checking Docker Compose... "
    if command_exists docker-compose || docker compose version >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Found${NC}"
        if command_exists docker-compose; then
            docker-compose --version
        else
            docker compose version
        fi
        return 0
    else
        echo -e "${RED}✗ Missing${NC}"
        return 1
    fi
}

# Function to check Git
check_git() {
    echo -n "Checking Git... "
    if command_exists git; then
        echo -e "${GREEN}✓ Found${NC}"
        git --version
        return 0
    else
        echo -e "${RED}✗ Missing${NC}"
        return 1
    fi
}

# Function to install missing dependencies
install_dependencies() {
    echo -e "\n${YELLOW}Installing missing dependencies...${NC}"
    
    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command_exists apt-get; then
            echo "Using apt-get (Debian/Ubuntu)..."
            sudo apt-get update
            
            if ! command_exists docker; then
                echo "Installing Docker..."
                curl -fsSL https://get.docker.com | sh
                sudo usermod -aG docker $USER
                echo -e "${YELLOW}Note: You may need to log out and back in for Docker permissions${NC}"
            fi
            
            if ! command_exists git; then
                echo "Installing Git..."
                sudo apt-get install -y git
            fi
            
        elif command_exists yum; then
            echo "Using yum (RedHat/CentOS)..."
            
            if ! command_exists docker; then
                echo "Installing Docker..."
                sudo yum install -y docker
                sudo systemctl start docker
                sudo systemctl enable docker
                sudo usermod -aG docker $USER
            fi
            
            if ! command_exists git; then
                echo "Installing Git..."
                sudo yum install -y git
            fi
        else
            echo -e "${RED}Unsupported Linux distribution${NC}"
            echo "Please install Docker, Docker Compose, and Git manually"
            return 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command_exists brew; then
            echo "Using Homebrew..."
            if ! command_exists docker; then
                echo "Installing Docker..."
                brew install docker
            fi
            if ! command_exists git; then
                echo "Installing Git..."
                brew install git
            fi
        else
            echo -e "${YELLOW}Please install Homebrew first: https://brew.sh${NC}"
            echo "Or install Docker Desktop manually: https://www.docker.com/products/docker-desktop"
            return 1
        fi
    else
        echo -e "${RED}Unsupported operating system: $OSTYPE${NC}"
        return 1
    fi
}

# Main dependency check
main() {
    local missing=0
    
    echo -e "\n${BLUE}Checking required dependencies:${NC}"
    
    if ! check_docker; then
        missing=$((missing + 1))
    fi
    
    if ! check_docker_compose; then
        missing=$((missing + 1))
    fi
    
    echo -e "\n${BLUE}Checking optional dependencies:${NC}"
    
    if ! check_git; then
        echo -e "${YELLOW}  (Git is needed for submodule management)${NC}"
    fi
    
    if [ $missing -gt 0 ]; then
        echo -e "\n${RED}❌ Missing $missing required dependencies${NC}"
        
        if [ "$1" = "--install" ]; then
            install_dependencies
        else
            echo -e "\n${YELLOW}Run with --install to automatically install missing dependencies:${NC}"
            echo "  $0 --install"
        fi
        return 1
    else
        echo -e "\n${GREEN}✅ All required dependencies found!${NC}"
        
        echo -e "\n${BLUE}Ready to use OpenProject Docker Compose:${NC}"
        echo "  docker-compose up -d"
        echo ""
        echo -e "${BLUE}To set up submodules:${NC}"
        echo "  git submodule update --init --recursive"
        
        return 0
    fi
}

# Run with --install flag to auto-install
main "$@"