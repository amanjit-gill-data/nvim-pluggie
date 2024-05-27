#!/usr/bin/bash

package_path="$XDG_CONFIG_HOME/nvim-data/site/pack/git_plugins/"
log_file="${package_path}plugin_log" 

# if --opt, installs plugin into opt/; otherwise installs into start/
# $1 = repo_url
# $2 = --opt | nothing
add_plugin() {

  # decide which dir to install into
  if [ "$2" = "--opt" ]; then
    parent_dir=opt/
  elif [ -z $2 ]; then
    parent_dir=start/
  else
    echo "Invalid option: $2"
    exit 1
  fi
 
  # check if remote exists
  check_remote $1

  dir=`basename $1 .git`

  # check if plugin already installed
  if [ `repo_exists $dir` -ne 0 ]; then
    echo $dir already exists.
    exit 1
  else
    echo -n Installing into $parent_dir$dir...
    echo `date` Install $dir into $parent_dir >> $log_file
    git clone --quiet $1 $package_path$parent_dir$dir &>> $log_file
    echo " done."
  fi
} 

# finds plugin in start/ or opt/ and removes it
# $1 = repo_dir
remove_plugin() {

  require_exists $1

  repo_path=`locate_repo $1`
  repo_parent=`basename $(dirname $repo_path)`/

  echo -n Removing $repo_parent$1...
  echo `date` Remove $repo_parent$1 >> $log_file
    
  cd $package_path$repo_parent
  rm -R -f $1 &>> $log_file
  echo " done."
}

# if no args, updates all plugins found in start/ and /opt
# if plugin name provided, finds plugin and updates it
# $1 = repo_dir | nothing
update_plugins() {

  if [ -z $1 ]; then

    cd $package_path
    find . -mindepth 2 -maxdepth 2 -type d | while read repo; do
      repo=${repo:2} # cut off the ./
      update_one $repo
    done
    
  else

    require_exists $1

    repo_path=`locate_repo $1`
    repo_parent=`basename $(dirname $repo_path)`/
    update_one $repo_parent$1
    
  fi
}

# no arguments
print_log() {

  if [ -z $1 ]; then
    less $log_file
  else 
    echo "Invalid argument provided."
  fi
}



# $1 = parent_dir/repo_dir
update_one() {
 
      echo -n Updating $1...
      echo `date` Update $1 >> $log_file
      cd $package_path$1
      git pull &>> $log_file
      echo " done."
}

# $1 = repo_dir
locate_repo() {

  find $package_path -mindepth 2 -maxdepth 2 -name $1
}

# $1 = repo_dir
repo_exists() {
  
  locate_repo $1 | wc -l
}

# $1 = repo_dir
require_exists() {
  
  if [ `repo_exists $1` -eq 0 ]; then
    echo $1 does not exist.
    exit 1
  fi
}

# $1 = repo_url
check_remote() {

  output=`git ls-remote $1 2>&1` # capture output to prevent print

  if [ $? -ne 0 ]; then
    echo "Unable to contact remote."
    exit 1
  fi
}

# $1 = arg supplied to add/remove
check_arg() {

  if [ -z $1 ]; then
    echo "Required argument missing."
    exit 1
  fi
}

# always start by ensuring plugin directories exist
mkdir -p ${package_path}start ${package_path}opt

# $1 = add|remove|update
# $2 = repo_url|repo_dir  
# $3 = --opt|nothing
case $1 in

  add)
    check_arg $2
    add_plugin $2 $3
    ;;

  remove)
    check_arg $2
    remove_plugin $2
    ;;
  
  update)
    update_plugins $2
    ;;

  log)
    print_log $2
    ;;

  *)
    echo "Required argument: add|remove|update|log."

esac



