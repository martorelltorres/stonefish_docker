#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "   DOCKER ROS STONEFISH INSTALLATION VERIFICATION TEST"
echo "   (cola2_msgs, stonefish_ros, cola2_stonefish)"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
}

fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
}

info() {
    echo -e "${YELLOW}ℹ INFO${NC}: $1"
}

section() {
    echo ""
    echo "────────────────────────────────────────────────────────────────"
    echo "  $1"
    echo "────────────────────────────────────────────────────────────────"
}

# ============================================================================
section "1. CONTAINER STATUS"
# ============================================================================

if docker compose ps | grep -q "ros-dev.*Up"; then
    pass "Container is running"
else
    fail "Container is not running"
    info "Run: docker compose up -d"
    exit 1
fi

# ============================================================================
section "2. BASE ROS INSTALLATION"
# ============================================================================

echo "Testing ROS Noetic..."
ROS_VERSION=$(docker compose exec -T ros-dev bash -c "source /opt/ros/noetic/setup.bash && rosversion -d" 2>/dev/null)
if [ "$ROS_VERSION" = "noetic" ]; then
    pass "ROS Noetic detected"
else
    fail "ROS Noetic not properly configured"
fi

echo ""
echo "Testing ROS tools..."
docker compose exec -T ros-dev bash -c "source /opt/ros/noetic/setup.bash && which roscore" &>/dev/null && pass "roscore available" || fail "roscore not found"
docker compose exec -T ros-dev bash -c "source /opt/ros/noetic/setup.bash && which rospack" &>/dev/null && pass "rospack available" || fail "rospack not found"

# ============================================================================
section "3. STONEFISH LIBRARY INSTALLATION"
# ============================================================================

echo "Checking Stonefish library files..."
if docker compose exec -T ros-dev test -f /usr/local/lib/libStonefish.so; then
    pass "Stonefish library file exists"
else
    fail "Stonefish library file NOT found"
fi

echo ""
echo "Checking Stonefish headers..."
if docker compose exec -T ros-dev test -d /usr/local/include/Stonefish; then
    pass "Stonefish headers directory exists"
    HEADER_COUNT=$(docker compose exec -T ros-dev bash -c "find /usr/local/include/Stonefish -name '*.h' | wc -l")
    info "Found $HEADER_COUNT header files"
else
    fail "Stonefish headers NOT found"
fi

echo ""
echo "Checking Stonefish CMake config..."
if docker compose exec -T ros-dev test -f /usr/local/lib/cmake/Stonefish/StonefishConfig.cmake; then
    pass "Stonefish CMake configuration exists"
else
    fail "Stonefish CMake configuration NOT found"
fi

# ============================================================================
section "4. CATKIN TOOLS"
# ============================================================================

echo "Testing catkin tools..."
CATKIN_VERSION=$(docker compose exec -T ros-dev catkin --version 2>/dev/null | head -1)
if [ -n "$CATKIN_VERSION" ]; then
    pass "Catkin tools installed"
    info "$CATKIN_VERSION"
else
    fail "Catkin tools not found"
fi

# ============================================================================
section "5. STONEFISH WORKSPACE STRUCTURE"
# ============================================================================

echo "Checking workspace at /home/rosuser/repo/stonefish_ws..."
if docker compose exec -T ros-dev test -d /home/rosuser/repo/stonefish_ws; then
    pass "Workspace directory exists"
else
    fail "Workspace directory NOT found"
    info "The workspace should be created automatically on first container run"
    exit 1
fi

echo ""
if docker compose exec -T ros-dev test -d /home/rosuser/repo/stonefish_ws/src; then
    pass "Source space exists"
else
    fail "Source space NOT found"
fi

echo ""
echo "Checking workspace build..."
if docker compose exec -T ros-dev test -d /home/rosuser/repo/stonefish_ws/devel; then
    pass "Devel space exists (workspace was built)"
else
    fail "Devel space NOT found (workspace not built)"
fi

echo ""
if docker compose exec -T ros-dev test -d /home/rosuser/repo/stonefish_ws/build; then
    pass "Build space exists"
else
    fail "Build space NOT found"
fi

# ============================================================================
section "6. CLONED REPOSITORIES"
# ============================================================================

echo "Checking cola2_msgs..."
if docker compose exec -T ros-dev test -d /home/rosuser/repo/stonefish_ws/src/cola2_msgs; then
    pass "cola2_msgs repository cloned"
    BRANCH=$(docker compose exec -T ros-dev bash -c "cd /home/rosuser/repo/stonefish_ws/src/cola2_msgs && git branch --show-current" 2>/dev/null)
    info "Current branch: $BRANCH"
    MSG_COUNT=$(docker compose exec -T ros-dev bash -c "find /home/rosuser/repo/stonefish_ws/src/cola2_msgs/msg -name '*.msg' 2>/dev/null | wc -l")
    info "Found $MSG_COUNT message files"
else
    fail "cola2_msgs NOT cloned"
fi

echo ""
echo "Checking stonefish_ros..."
if docker compose exec -T ros-dev test -d /home/rosuser/repo/stonefish_ws/src/stonefish_ros; then
    pass "stonefish_ros repository cloned"
    BRANCH=$(docker compose exec -T ros-dev bash -c "cd /home/rosuser/repo/stonefish_ws/src/stonefish_ros && git branch --show-current" 2>/dev/null)
    info "Current branch: $BRANCH"
else
    fail "stonefish_ros NOT cloned"
fi

echo ""
echo "Checking cola2_stonefish..."
if docker compose exec -T ros-dev test -d /home/rosuser/repo/stonefish_ws/src/cola2_stonefish; then
    pass "cola2_stonefish repository cloned"
    BRANCH=$(docker compose exec -T ros-dev bash -c "cd /home/rosuser/repo/stonefish_ws/src/cola2_stonefish && git branch --show-current" 2>/dev/null)
    info "Current branch: $BRANCH"
else
    fail "cola2_stonefish NOT cloned"
fi

# ============================================================================
section "7. ROS PACKAGE DETECTION"
# ============================================================================

echo "Testing ROS package system..."
COLA2_MSGS_PATH=$(docker compose exec -T ros-dev bash -c "source /home/rosuser/repo/stonefish_ws/devel/setup.bash 2>/dev/null && rospack find cola2_msgs 2>/dev/null")
if [ -n "$COLA2_MSGS_PATH" ]; then
    pass "cola2_msgs found by ROS"
    info "Path: $COLA2_MSGS_PATH"
else
    fail "cola2_msgs NOT found by ROS"
fi

echo ""
STONEFISH_ROS_PATH=$(docker compose exec -T ros-dev bash -c "source /home/rosuser/repo/stonefish_ws/devel/setup.bash 2>/dev/null && rospack find stonefish_ros 2>/dev/null")
if [ -n "$STONEFISH_ROS_PATH" ]; then
    pass "stonefish_ros found by ROS"
    info "Path: $STONEFISH_ROS_PATH"
else
    fail "stonefish_ros NOT found by ROS"
fi

echo ""
COLA2_STONEFISH_PATH=$(docker compose exec -T ros-dev bash -c "source /home/rosuser/repo/stonefish_ws/devel/setup.bash 2>/dev/null && rospack find cola2_stonefish 2>/dev/null")
if [ -n "$COLA2_STONEFISH_PATH" ]; then
    pass "cola2_stonefish found by ROS"
    info "Path: $COLA2_STONEFISH_PATH"
else
    fail "cola2_stonefish NOT found by ROS"
fi

echo ""
echo "Listing all workspace packages..."
PACKAGES=$(docker compose exec -T ros-dev bash -c "source /home/rosuser/repo/stonefish_ws/devel/setup.bash 2>/dev/null && rospack list 2>/dev/null | grep -E '(cola2|stonefish)' | wc -l")
info "Found $PACKAGES packages registered in ROS"

# ============================================================================
section "8. PACKAGE DEPENDENCIES"
# ============================================================================

echo "Checking cola2_stonefish dependencies..."
DEPS=$(docker compose exec -T ros-dev bash -c "source /home/rosuser/repo/stonefish_ws/devel/setup.bash 2>/dev/null && rospack depends cola2_stonefish 2>/dev/null" | head -10)
if [ -n "$DEPS" ]; then
    pass "Dependencies detected for cola2_stonefish"
    echo "$DEPS" | head -5 | while read line; do
        info "  - $line"
    done
else
    info "No dependencies listed or package not found"
fi

echo ""
echo "Checking stonefish_ros dependencies..."
DEPS=$(docker compose exec -T ros-dev bash -c "source /home/rosuser/repo/stonefish_ws/devel/setup.bash 2>/dev/null && rospack depends stonefish_ros 2>/dev/null" | head -10)
if [ -n "$DEPS" ]; then
    pass "Dependencies detected for stonefish_ros"
    echo "$DEPS" | head -5 | while read line; do
        info "  - $line"
    done
else
    info "No dependencies listed or package not found"
fi

# ============================================================================
section "9. LAUNCH FILES"
# ============================================================================

echo "Searching for launch files in stonefish_ros..."
LAUNCH_FILES=$(docker compose exec -T ros-dev bash -c "find /home/rosuser/repo/stonefish_ws/src/stonefish_ros -name '*.launch' 2>/dev/null" | head -10)
if [ -n "$LAUNCH_FILES" ]; then
    LAUNCH_COUNT=$(echo "$LAUNCH_FILES" | wc -l)
    pass "Found $LAUNCH_COUNT launch files in stonefish_ros"
    echo "$LAUNCH_FILES" | head -5 | while read line; do
        BASENAME=$(basename "$line")
        info "  - $BASENAME"
    done
else
    info "No launch files found in stonefish_ros"
fi

echo ""
echo "Searching for launch files in cola2_stonefish..."
LAUNCH_FILES=$(docker compose exec -T ros-dev bash -c "find /home/rosuser/repo/stonefish_ws/src/cola2_stonefish -name '*.launch' 2>/dev/null" | head -10)
if [ -n "$LAUNCH_FILES" ]; then
    LAUNCH_COUNT=$(echo "$LAUNCH_FILES" | wc -l)
    pass "Found $LAUNCH_COUNT launch files in cola2_stonefish"
    echo "$LAUNCH_FILES" | head -5 | while read line; do
        BASENAME=$(basename "$line")
        info "  - $BASENAME"
    done
else
    info "No launch files found in cola2_stonefish"
fi

# ============================================================================
section "10. BUILT PACKAGES"
# ============================================================================

echo "Checking built packages in devel space..."
if docker compose exec -T ros-dev test -d /home/rosuser/repo/stonefish_ws/devel/.private/cola2_msgs; then
    pass "cola2_msgs was built"
else
    fail "cola2_msgs build artifacts NOT found"
fi

echo ""
if docker compose exec -T ros-dev test -d /home/rosuser/repo/stonefish_ws/devel/.private/stonefish_ros; then
    pass "stonefish_ros was built"
else
    fail "stonefish_ros build artifacts NOT found"
fi

echo ""
if docker compose exec -T ros-dev test -d /home/rosuser/repo/stonefish_ws/devel/.private/cola2_stonefish; then
    pass "cola2_stonefish was built"
else
    fail "cola2_stonefish build artifacts NOT found"
fi

# ============================================================================
section "11. MESSAGE GENERATION"
# ============================================================================

echo "Checking if cola2_msgs messages were generated..."
GENERATED_MSGS=$(docker compose exec -T ros-dev bash -c "find /home/rosuser/repo/stonefish_ws/devel/.private/cola2_msgs/include/cola2_msgs -name '*.h' 2>/dev/null | wc -l")
if [ "$GENERATED_MSGS" -gt "0" ]; then
    pass "cola2_msgs message headers generated"
    info "Found $GENERATED_MSGS generated message headers"
else
    fail "cola2_msgs message headers NOT found"
fi

# ============================================================================
section "12. PYTHON ENVIRONMENT"
# ============================================================================

echo "Testing Python packages..."
docker compose exec -T ros-dev python3 -c "import cv2" 2>/dev/null && pass "OpenCV installed" || fail "OpenCV not found"
docker compose exec -T ros-dev python3 -c "import matplotlib" 2>/dev/null && pass "Matplotlib installed" || fail "Matplotlib not found"
docker compose exec -T ros-dev python3 -c "import tkinter" 2>/dev/null && pass "Tkinter installed" || fail "Tkinter not found"

# ============================================================================
section "13. BUILD LOGS SUMMARY"
# ============================================================================

echo "Checking if build logs exist..."
if docker compose exec -T ros-dev test -d /home/rosuser/repo/stonefish_ws/logs; then
    pass "Build logs directory exists"
    LOG_PACKAGES=$(docker compose exec -T ros-dev ls /home/rosuser/repo/stonefish_ws/logs 2>/dev/null | wc -l)
    info "Found logs for $LOG_PACKAGES packages"
else
    fail "Build logs directory not found"
fi

echo ""
echo "Checking stonefish_ros build log..."
if docker compose exec -T ros-dev test -f /home/rosuser/repo/stonefish_ws/logs/stonefish_ros/build.make.000.log; then
    pass "stonefish_ros build log exists"
    echo ""
    info "Last 5 lines of stonefish_ros build log:"
    docker compose exec -T ros-dev tail -5 /home/rosuser/repo/stonefish_ws/logs/stonefish_ros/build.make.000.log | sed 's/^/     /'
else
    info "stonefish_ros build log not found"
fi

echo ""
echo "Checking cola2_stonefish build log..."
if docker compose exec -T ros-dev test -f /home/rosuser/repo/stonefish_ws/logs/cola2_stonefish/build.make.000.log; then
    pass "cola2_stonefish build log exists"
    echo ""
    info "Last 5 lines of cola2_stonefish build log:"
    docker compose exec -T ros-dev tail -5 /home/rosuser/repo/stonefish_ws/logs/cola2_stonefish/build.make.000.log | sed 's/^/     /'
else
    info "cola2_stonefish build log not found"
fi

# ============================================================================
section "14. ENVIRONMENT CONFIGURATION"
# ============================================================================

echo "Checking bashrc configuration..."
docker compose exec -T ros-dev grep -q "stonefish_ws/devel/setup.bash" /home/rosuser/.bashrc && pass "Workspace sourced in bashrc" || fail "Workspace not in bashrc"

echo ""
echo "Checking environment variables..."
docker compose exec -T ros-dev bash -c "source /opt/ros/noetic/setup.bash && printenv | grep ROS_DISTRO" &>/dev/null && pass "ROS_DISTRO set" || fail "ROS_DISTRO not set"

echo ""
echo "Checking workspace overlay..."
ROS_PACKAGE_PATH=$(docker compose exec -T ros-dev bash -c "source /home/rosuser/repo/stonefish_ws/devel/setup.bash && echo \$ROS_PACKAGE_PATH" | grep stonefish_ws)
if [ -n "$ROS_PACKAGE_PATH" ]; then
    pass "Workspace correctly overlaid on ROS_PACKAGE_PATH"
else
    fail "Workspace not in ROS_PACKAGE_PATH"
fi

# ============================================================================
section "15. HOST ACCESSIBILITY CHECK"
# ============================================================================

echo "Verifying workspace is accessible from host..."
if [ -d "./stonefish_ws" ]; then
    pass "Workspace directory visible on host"
    if [ -d "./stonefish_ws/src" ]; then
        pass "Source code accessible from host"
        SRC_DIRS=$(ls -1 ./stonefish_ws/src | wc -l)
        info "Found $SRC_DIRS items in src directory on host"
    else
        fail "Source directory not accessible from host"
    fi
else
    fail "Workspace not visible on host filesystem"
    info "Check that the bind mount ./:/home/rosuser/repo is working"
fi

# ============================================================================
section "16. QUICK FUNCTIONAL TEST"
# ============================================================================

echo "Testing if rospack can list stonefish packages..."
STONEFISH_PACKAGES=$(docker compose exec -T ros-dev bash -c "source /home/rosuser/repo/stonefish_ws/devel/setup.bash && rospack list-names | grep -E '(cola2|stonefish)'" 2>/dev/null)
if [ -n "$STONEFISH_PACKAGES" ]; then
    PACKAGE_COUNT=$(echo "$STONEFISH_PACKAGES" | wc -l)
    pass "rospack can list packages ($PACKAGE_COUNT found)"
    echo "$STONEFISH_PACKAGES" | while read pkg; do
        info "  - $pkg"
    done
else
    fail "rospack cannot list stonefish packages"
fi

# ============================================================================
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "                    TEST SUMMARY"
echo "════════════════════════════════════════════════════════════════"
echo ""
info "Review the results above to verify your installation"
echo ""
echo "Key success indicators:"
echo "  • Stonefish library and headers exist"
echo "  • Workspace at /home/rosuser/repo/stonefish_ws built successfully"
echo "  • All 3 packages (cola2_msgs, stonefish_ros, cola2_stonefish) found by ROS"
echo "  • Launch files available in both stonefish_ros and cola2_stonefish"
echo "  • Messages generated for cola2_msgs"
echo "  • Workspace accessible from host filesystem"
echo ""
echo "════════════════════════════════════════════════════════════════"
