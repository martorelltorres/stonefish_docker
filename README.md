# Docker Development Environment for ROS Noetic with Stonefish

This repository provides a dockerized development environment for ROS Noetic applications with Stonefish simulator support and Python 3.8, based on the official ROS Noetic Desktop Full image.

## Overview

This Docker environment uses Ubuntu 20.04 with ROS Noetic Desktop Full, Python 3.8, and Stonefish simulator. The workspace is automatically initialized on first run and persists on your host machine for easy editing with your IDE.

### What's Included

- ROS Noetic Desktop Full with complete GUI tools (rviz, rqt, Gazebo)
- Stonefish library built from source
- Pre-configured catkin workspace with packages:
  - stonefish_ros (branch: master)
  - cola2_stonefish (branch: noetic-24.01-MRS)
- NVIDIA GPU support for simulation rendering
- ROS Noetic Rosbridge suite
- X11 forwarding for GUI applications
- Python development environment with OpenCV, Matplotlib, and Tkinter
- Catkin-tools for workspace management

## Requirements

To use this development environment, you need:

- Docker Engine 20.10+ with Docker Compose
- NVIDIA GPU with drivers installed supporting at least cuda 12.4
- NVIDIA Container Toolkit (nvidia-docker2)
- X11 server for graphical forwarding:
  - Locally: X server running on your machine
  - Remote (SSH): SSH with X11 forwarding configured

## Folder Structure

Your development repo should have the following structure:
```
repo
  |___ dataset/
  |___ src/
  |___ stonefish_ws/
  |___ docker-compose.yml
  |___ docker-entrypoint.sh
  |___ Dockerfile.ros_base
  |___ requirements_py38.txt
  |___ .env
```

It may contain other folders or files, but this is the basic setup. Here is what each item is for:

- `dataset`: Empty folder locally, mapped to the dataset specified in the DATASET environment variable
- `src`: Contains all project code
- `stonefish_ws`: Folder for simulation workspace
- `docker-compose.yml`: The file used by docker compose to launch the system. Do not modify it
- `Dockerfile.ros_base`: The file that builds the ROS Noetic image. Do not modify it
- `docker-entrypoint.sh`: Necessary script to clone `stonefish_ros`and `cola2_stonefish` once the system is up.
- `requirements_py38.txt`: Python requirements file for ROS container. If you need more libraries, add them here
- `.env`: The file where environment variables are defined

## Environment Variables (.env file)

Required variables in your .env file:

- PROJECT_NAME: Container and network naming prefix to avoid conflicts
- DATASET: Path to dataset directory on host
- CONTAINER_DISPLAY: X11 display (usually :0 or :1 for local, and IP_ADDR:PORT for remote)

Optional variables in your .env file:

- UID: Your user ID (run: id -u)
- GID: Your group ID (run: id -g)
- XAUTHORITY: Path to X authority file for X11 forwarding in local operation or via AnyDesk.
- DEBUG_PORT: Port for debugging. 5678 by default.

Important: Add .env to .gitignore to avoid committing local configuration.

## Quick Start

### 1. Create New Project from Template

**Using GitHub Web Interface:**
1. Click "Use this template" button
2. Create your new repository
3. Clone locally: `git clone https://github.com/your-username/your-project.git`

### 2. Initialize Project

1. Convert the `dotenv.template` file into your `.env` file with your project settings.
Configure your `.env` file as described in the section below `3. Configure Environment`.

2. Add your additional dependencies to `requirements_py38.txt`

3. Open a terminal in the current folder and type `docker compose up -d`.

### 3. Configure Environment

Edit the `.env` file with your project-specific settings:

```
# Name of the project. It is also used for the prefix of the container
PROJECT_NAME = MyNewProject

# X11 display for GUI. You can use :0 or :1 for local. You can also use
# IP_ADDR:PORT if connected remotely via ssh
CONTAINER_DISPLAY = :1

# Path to the dataset at the host
DATASET = /path/to/your/dataset/at/host

# Optionals:
# Debug port. Default 5678
DEBUG_PORT = 5678

# User ID and group ID
UID = 1000
GID = 1000

# Path to X authority file
XAUTHORITY = /run/user/1000/gdm/Xauthority
```

### 4. Add Dependencies

Update `requirements_py38.txt` with your project dependencies.


### 5. Build and Run

**Build and start the development environment**

```
docker compose up -d
```

Also you can force rebuild with
```
docker compose up --build -d
```

Or even force build without using cache
```
docker compose build --no-cache
docker compose up -d
```

**Access the running container**

```
docker compose exec ros-dev bash
```

But I recommend you use VSCode or Cursor with DevContainers and select the option "_Attach to running container_"

**Finish session**

```
docker compose down
```

The container will be removed, but all your changes will remain in the folders and scripts of the project outside the container. Here is where you can use git to version control.


## How It Works

### First Container Run

When you run `docker compose up -d` for the first time:

1. Container starts with docker-entrypoint.sh
2. Script checks if /home/rosuser/repo/stonefish_ws exists
3. If not, it automatically:
   - Creates catkin workspace structure
   - Clones cola2_msgs, stonefish_ros, and cola2_stonefish repositories
   - Checks out correct branches
   - Builds all packages with catkin build
4. Workspace is now available in `./stonefish_ws/` on your host

### Subsequent Runs

On every subsequent run:
- Entrypoint detects existing workspace
- Skips initialization
- Sources the workspace
- Your modifications are preserved

### Persistence

Because of the bind mount `./:/home/rosuser/repo`:
- All files are stored on your host machine
- You can edit source code, launch files, and configs with your IDE
- Changes persist even when container is removed
- You can commit and push your modifications to git


## Testing the Installation

### General test

Run the comprehensive test script:
```
chmod +x test_installation.sh
./test_installation.sh
```

The script verifies:
- Container status
- ROS Noetic installation
- Stonefish library
- Catkin tools
- Workspace structure
- All three packages cloned and built
- ROS package detection
- Launch files availability
- Message generation
- Python environment
- Host filesystem accessibility

### Test X11 Forwarding

From outside the container:

```
$ docker compose exec ros-dev xeyes
```
You should see animated eyes on your screen, confirming X11 forwarding works correctly.

### Test ROS GUI Applications

Attach to the running container:

```
$ docker attach ${PROJECT_NAME}-ros
```
Or use VSCode to attach to the running container. Then run:
```
$ roscore | rqt_image_view
```

The ROS GUI should appear on your screen. If it doesn't, check:
- Firewall configuration on the host
- X11 forwarding setup (SSH configuration)
- Local X server permissions (try `xhost +` if working locally, though this is not recommended for security)

### Test GPU Support

Check if NVIDIA GPU is accessible:
```
$ docker compose exec ros-dev nvidia-smi
```

## SSH Configuration for Visualization

If you are connecting via SSH and want to visualize ROS GUI applications remotely:

### On Your Local Computer

1. Edit `~/.ssh/config` to enable X11 forwarding and remote forwarding:
```
Host your_host
  HostName 172.XX.XX.XX
  User PepitoGrillo
  RemoteForward *:6030 /tmp/.X11-unix/X1
  ForwardX11 yes
  ForwardX11Trusted yes
```
**Important notes:**
- The port `6030` corresponds to port `30` chosen in `CONTAINER_DISPLAY` (format: `60XX` where XX is your chosen port)
- The `/tmp/.X11-unix/X1` should match your local `$DISPLAY` value. If `echo $DISPLAY` returns `:0`, use `X0` instead of `X1`

### On the Host

2. Verify that `/etc/ssh/sshd_config` has these settings:

```
GatewayPorts yes
X11Forwarding yes
X11DisplayOffset 10  # This is the default value. If it is commented out, that's fine.
X11UseLocalhost no
```
And then restart ssh (`systemctl restart ssh`)

3. Configure the host firewall (ufw) to allow X11 traffic (if ufw is enabled):
```
$ sudo ufw prepend allow proto tcp from 172.16.0.0/12 to any port 6000:6050
```
This rule allows ports 6000-6050 from Docker networks, covering all current and
future networks created by docker-compose.
This way X11-forwarding should work, but only if you have your local setup as `xhost +`;
otherwise it will probably fail.

## License

This Docker configuration is provided as-is for development purposes. Individual components (ROS, Stonefish, cola2 packages) have their own licenses.

## Acknowledgments

- Based on ROS Noetic Desktop Full official image
- Stonefish simulator by Patryk Cieślak
- cola2_msgs, stonefish_ros, and cola2_stonefish packages from SRV organization
- All repositories are publicly available on GitHub
