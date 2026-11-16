#!/bin/bash
set -e

# ==============================================================================
# NEXUS DATA SYSTEMS - WORKSTATION STANDARDIZATION PROJECT
# ==============================================================================
# Authored by: OmniStack Infrastructure Consulting
# Target Environment: Headless Linux / Backend Analytics
#
# Purpose: Automated provisioning of developer workstation environments to 
# ensure consistent tooling, strict permissions, and proper directory structures.
#
# INSTRUCTIONS:
# Insert the exact command-line instructions beneath each structured comment block 
# to satisfy the onboarding requirements for the new Data Engineering cohort.
# ==============================================================================

echo "[INFO] Initiating Nexus Developer Workstation Setup..."

# ------------------------------------------------------------------------------
# Step 1: Directory Creation
# Requirement: Create a standardized directory structure containing 'projects/', 
# 'logs/', and 'configs/' directly within the current working directory using 
# a single command.
# ------------------------------------------------------------------------------
echo "[INFO] Step 1: Building directory structure..."
# Create all three directories in one command; -p avoids errors if they already exist.
mkdir -p projects logs configs

# ------------------------------------------------------------------------------
# Step 2: Generate Configuration Files
# Requirement: Generate placeholder configuration files named 'database.conf' 
# and 'app.properties' inside the newly created 'configs/' directory.
# ------------------------------------------------------------------------------
echo "[INFO] Step 2: Generating placeholder configurations..."
# 'touch' creates empty placeholder files inside configs/.
touch configs/database.conf configs/app.properties

# ------------------------------------------------------------------------------
# Step 3: Package Installation
# Requirement: Install standard network and text diagnostics packages 
# non-interactively using apt: 'curl', 'htop', and 'nano'.
# (Assume the script is run with adequate privileges or prefix with sudo if needed)
# ------------------------------------------------------------------------------
echo "[INFO] Step 3: Installing essential packages via apt..."
# Use sudo only when not already root. DEBIAN_FRONTEND=noninteractive and -y
# suppress every prompt so the script runs unattended. 'tree' is included per
# spec NDS-WSS-104 section 3.
if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi
$SUDO apt update -y
$SUDO env DEBIAN_FRONTEND=noninteractive apt install -y curl htop nano tree

# ------------------------------------------------------------------------------
# Step 4: Ownership and Permissions
# Requirement A: Modify group ownership of the 'projects/' directory to a 
# group named 'data_engineers' (assume the group already exists).
# Requirement B: Apply strict rwx file permissions to all files in 'configs/' 
# so that only the file owner has read and write access (numeric mode 600).
# ------------------------------------------------------------------------------
echo "[INFO] Step 4: Securing configs and setting group ownership..."
# A: set group ownership of projects/ to data_engineers (group must already exist).
chgrp data_engineers projects
# Spec NDS-WSS-104 section 5: owner and group get rwx (770), others get nothing.
chmod 770 projects

# B: owner-only read/write (600) on every file in configs/; no access for group/others.
chmod 600 configs/*

# ------------------------------------------------------------------------------
# Step 5: Environment Variables
# Requirement: Append the environment variable export 'export NEXUS_ENV=production' 
# to the user's '.bashrc' file utilizing standard shell redirection operators, 
# ensuring existing content is not overwritten.
# ------------------------------------------------------------------------------
echo "[INFO] Step 5: Setting NEXUS_ENV in .bashrc..."
# '>>' APPENDS to ~/.bashrc; a single '>' would overwrite the user's profile.
echo 'export NEXUS_ENV=production' >> "$HOME/.bashrc"

# ------------------------------------------------------------------------------
# Step 6: Process Snapshot
# Requirement: Execute a process snapshot command that lists all running daemons 
# and processes, utilizing a pipe or redirection operator to output the result 
# to 'logs/processes.log'.
# ------------------------------------------------------------------------------
echo "[INFO] Step 6: Capturing baseline process snapshot..."
# 'ps aux' lists every process (including daemons); '>' writes the snapshot to the log.
ps aux > logs/processes.log

echo "[SUCCESS] Workstation provisioning script completed without errors."
