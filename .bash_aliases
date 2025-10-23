#!/bin/bash
# -*- coding: utf-8 -*-
# Bash aliases for ROS/COLA2 development environment

# General navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias sbash='source ~/.bashrc'
alias vbash='vi ~/.bashrc'
alias gbash='gedit ~/.bashrc'
alias valias='vi ~/.bash_aliases'
alias galias='gedit ~/.bash_aliases'

# Git shortcuts
alias gits='git status'

# ROS Master URI configurations
alias uri_home='export ROS_MASTER_URI=http://localhost:11311'
alias uri_turbot='export ROS_MASTER_URI=http://192.168.1.205:11311'
alias uri_orat='export ROS_MASTER_URI=http://192.168.1.71:11311'
alias uri_xiroi='export ROS_MASTER_URI=http://192.168.1.207:11311'
alias uri_gs_turbot='export ROS_MASTER_URI=http://192.168.1.172:11311'
alias uri_gs_orat='export ROS_MASTER_URI=http://192.168.1.50:11311'
alias uri_pulgarcito='export ROS_MASTER_URI=http://192.168.1.100:11311'
alias uri_lanty2='export ROS_MASTER_URI=http://192.168.1.191:11311'

# ROS topic shortcuts
alias techo='rostopic echo'
alias tlist='rostopic list'
alias tinfo='rostopic info'
alias tgrep='tlist | grep'

# ROS bag shortcuts
alias bagi='rosbag info'
alias bagp='rosbag play'

# ROS visualization
alias rviz='rosrun rviz rviz'
alias tf='cd /var/tmp && rosrun tf view_frames && evince frames.pdf &'

# COLA2 - Catkin workspace
alias catkin_ws='cd ~/catkin_ws'
alias cola2_ws='cd ~/repo/catkin_ws'
alias cws='cd ~/repo/catkin_ws'
alias cb='cd ~/repo/catkin_ws && catkin build'
alias cbs='cd ~/repo/catkin_ws && source devel/setup.bash'

# Build utilities
alias make='make -j$(nproc)'

