#!/bin/bash
# -*- coding: utf-8 -*-
# Entrypoint script for COLA2 + Stonefish development environment
# This script initializes the catkin workspace on first run and sources
# the ROS environment for subsequent runs.
#
# The workspace is created inside the bind-mounted /home/rosuser/repo
# directory, allowing the source code to persist on the host.

# Catkin workspace path inside bind-mounted directory
CATKIN_WS="/home/rosuser/repo/catkin_ws"
SRC_DIR="${CATKIN_WS}/src"
DEVEL_SETUP="${CATKIN_WS}/devel/setup.bash"


echo "════════════════════════════════════════════════════════════════"
echo "  Initializing catkin workspace (first run only)"
echo "  Location: ${CATKIN_WS}"
echo "════════════════════════════════════════════════════════════════"

# Create source directory
mkdir -p "$SRC_DIR"
cd "$CATKIN_WS"

# Initialize catkin workspace
source /opt/ros/noetic/setup.bash
echo "Initializing catkin workspace..."
catkin init

# Clone repositories
cd "$SRC_DIR"

echo ""
echo "────────────────────────────────────────────────────────────────"
echo "  Cloning COLA2 core packages..."
echo "────────────────────────────────────────────────────────────────"

# Clone cola2_msgs
echo "Cloning cola2_msgs (branch: v1.3)..."
if git https://github.com/srv/cola2_msgs.git 2>/dev/null; then
    cd cola2_msgs && git checkout v1.3 && cd ..
else
    echo "Warning: cola2_msgs clone failed. Skipping..."
fi

# Clone cola2_lib_ros
echo "Cloning cola2_lib_ros..."
if git clone https://github.com/srv/cola2_lib_ros.git 2>/dev/null; then
    cd cola2_lib_ros
git checkout noetic-24.01 2>/dev/null || echo "Using default branch"
cd ..
else
    echo "Warning: cola2_lib_ros clone failed. Skipping..."
fi

# Clone cola2_core 
echo "Cloning cola2_core..."
if git clone https://github.com/srv/cola2_core.git 2>/dev/null; then
    cd cola2_core
    git checkout noetic-24.01 2>/dev/null || echo "Using default branch"
    cd ..
else
    echo "Warning: cola2_core clone failed. Skipping..."
fi

echo ""
echo "────────────────────────────────────────────────────────────────"
echo "  Cloning vehicle-specific packages..."
echo "────────────────────────────────────────────────────────────────"

# Clone SparusII packages
echo "Cloning sparus2_description..."
if git clone https://github.com/srv/sparus2_description.git 2>/dev/null; then
    cd sparus2_description
    git checkout noetic-24.01 2>/dev/null || echo "Using default branch"
    cd ..
else
    echo "Warning: sparus2_description clone failed. Skipping..."
fi

echo "Cloning cola2_sparus2..."
if git clone https://github.com/srv/cola2_sparus2.git 2>/dev/null; then
    cd cola2_sparus2
    git checkout noetic-24.01 2>/dev/null || echo "Using default branch"
    cd ..
else
    echo "Warning: cola2_sparus2 clone failed. Skipping..."
fi

# Clone Girona500 packages
echo "Cloning girona500_description..."
if git clone https://github.com/srv/girona500_description.git 2>/dev/null; then
    cd girona500_description
    git checkout v1.3 2>/dev/null || echo "Using default branch"
    cd ..
else
    echo "Warning: girona500_description clone failed. Skipping..."
fi

echo "Cloning cola2_girona500..."
if git clone https://github.com/srv/cola2_girona500.git 2>/dev/null; then
    cd cola2_girona500
    git checkout v1.3 2>/dev/null || echo "Using default branch"
    cd ..
else
    echo "Warning: cola2_girona500 clone failed. Skipping..."
fi
# Clone Stonefish packages
echo ""
echo "────────────────────────────────────────────────────────────────"
echo "  Cloning Stonefish packages..."
echo "────────────────────────────────────────────────────────────────"

echo "Cloning stonefish_ros (tag: v1.3)..."
if git clone https://github.com/srv/stonefish_ros.git; then
    cd stonefish_ros && git checkout v1.3 && cd ..
    echo "Cloning stonefish_ros"
else
    echo "Warning: stonefish_ros clone failed. Skipping..."
fi

echo "Cloning cola2_stonefish (branch: noetic-24.01-MRS)..."
if git clone https://github.com/srv/cola2_stonefish.git; then
    cd cola2_stonefish && git checkout v1.3 && cd ..
    echo "Cloning cola2_stonefish"
else
    echo "Warning: cola2_stonefish clone failed. Skipping..."
fi

# Build the workspace
cd "$CATKIN_WS"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Building catkin workspace (this may take several minutes)..."
echo "════════════════════════════════════════════════════════════════"
catkin build

BUILD_STATUS=$?
if [ $BUILD_STATUS -eq 0 ]; then
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  Workspace initialized and built successfully!"
    echo "  Location: ${CATKIN_WS}"
    echo "  Available vehicles: SparusII (default), Girona500"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
else
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  WARNING: Workspace build encountered errors!"
    echo "  Please check the error messages above."
    echo "════════════════════════════════════════════════════════════════"
    echo ""
fi


# Source ROS environment
source /opt/ros/noetic/setup.bash

# Source the workspace if it exists and is built
if [ -f "$DEVEL_SETUP" ]; then
    source "$DEVEL_SETUP"
    echo "ROS environment configured and ready!"
    echo ""
    echo "Workspace information:"
    echo "  Workspace: ${CATKIN_WS}"
    echo "  ROS_PACKAGE_PATH: ${ROS_PACKAGE_PATH}"
    echo "  ROS_MASTER_URI: ${ROS_MASTER_URI}"
    echo ""
    echo "Quick commands:"
    echo "  roscd           - Navigate to workspace root"
    echo "  roscd <package> - Navigate to a specific package"
    echo "  rospack list    - List all available packages"
    echo "  catkin build    - Rebuild the workspace"
    echo ""
fi

# Execute the command passed to the container
exec "$@"
