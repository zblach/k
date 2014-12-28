k() {

  # ----------------------------------------------
  # TODO: Check bash version, need v4 as minimum
  # for `typeset -A` ie. associative arrays

  # ----------------------------------------------
  # Shell specific stuff to make k consistent
  # across zsh and bash
  if [ -n "${ZSH_VERSION}" ]; then
    # ZSH
    # ksh_array option so zsh array[@] starts at 0
    setopt ksh_arrays local_options
  # else
  #   # BASH
  fi


  # ----------------------------------------------
  # Constant - should be uppercase but that sucks
  typeset -a file_var_names
  file_var_names=(
    blocks
    permissions
    hard_link_count
    owner
    group
    file_size
    epoch
    day
    month
    time_of_day
    year
    name
    symlink_marker
    symlink_target
  )


  # ----------------------------------------------------------------------------
  # Stat each file and loop through

  for file in .* *
  do
    typeset -a stat
    typeset -A file_vars
    typeset -i i=0
    typeset -i file_count=1
    # typeset -i is_directory is_symlink is_executable

    # Stat call on each file, the format matches
    # this list of file_names_vars above
    stat=(
      $(stat -L \
      -f "%b %Sp %l %Su %Sg %z %Sm %N %SY" \
      -t "%s %d %b %H:%M %Y" \
      ${file})
    )

    # Associative array of file_var_names and file_vars
    for stat_var in "${stat[@]}"
    do
      file_vars[${file_var_names[$i]}]=${stat_var[@]}
      i+=1
    done

        permissions="${file_vars[permissions]}"
    hard_link_count="${file_vars[hard_link_count]}"
              owner="${file_vars[owner]}"
              group="${file_vars[group]}"
          file_size="${file_vars[file_size]}"
               date="${file_vars[day]} ${file_vars[month]} ${file_vars[time_of_day]} ${file_vars[year]}"
               name="${file_vars[name]}"
     symlink_marker="${file_vars[symlink_marker]}"
     symlink_target="${file_vars[symlink_target]}"


    # --------------------------------------------------------------------------
    # Check the git status
    # First checking directories, then checking files.

    is_git_repo=0
     git_marker=" "
     git_status=""

    # Are we currently inside a git repo
    if [[ $(command git rev-parse --is-inside-work-tree 2>/dev/null) == true ]]
      then
      is_git_repo=1
    fi;

    # Check if directory in PWD are git repos and report clean or dirty
    if (( !is_git_repo ))
    then
      if (( is_directory )) && [[ -d "$name/.git" ]]
      then
        if command git --git-dir="$PWD/$name/.git" --work-tree="$PWD/$name" diff --quiet --ignore-submodules HEAD &>/dev/null # if dirty
          then git_marker=$'\e[0;32m|\e[0m' # Show a green vertical bar for dirty
          else git_marker=$'\e[0;31m|\e[0m' # Show a red vertical bar if clean
        fi
      fi
    fi

    if (( is_git_repo )) && [[ "$name" != '.' ]] && [[ "$name" != '..' ]] && [[ "$name" != '.git' ]]
      then
      git_status="$(command git status --porcelain --ignored --untracked-files=normal "$name")"
      sub_status="${git_status:0:2}"
        if [[ $sub_status == ' M' ]]; then git_marker=$'\e[0;31m|\e[0m';     # Modified
      elif [[ $sub_status == '??' ]]; then git_marker=$'\e[38;5;214m|\e[0m'; # Untracked
      elif [[ $sub_status == '!!' ]]; then git_marker=$'\e[38;5;238m|\e[0m'; # Ignored
      elif [[ $sub_status == 'A ' ]]; then git_marker=$'\e[38;5;093m|\e[0m'; # Added
      else                             git_marker=$'\e[0;32m|\e[0m';     # Good
      fi
    fi


    # --------------------------------------------------------------------------
    # Colour file names

     is_directory=0
       is_symlink=0
    is_executable=0

    # Check file types
    if [[ -d "$name" ]]; then is_directory=1; fi
    if [[ -L "$name" ]]; then   is_symlink=1; fi

    # Check if file is executable
    if [[ ${permissions:3:1} == "x" || ${permissions:6:1} == "x" || ${permissions:9:1} == "x" ]]; then is_executable=1; fi

    if (( is_directory ))
    then
      name=$'\e[1;34m'"$name"$'\e[0m'
    elif (( is_symlink ))
    then
      name=$'\e[0;35m'"$name"$'\e[0m'
    elif (( is_executable ))
    then
      name=$'\e[0;31m'"$name"$'\e[0m'
    fi


    # --------------------------------------------------------------------------
    # Format and Print final result
    echo $permissions \
         $hard_link_count \
         $owner \
         $group \
         $file_size \
         $date \
         "$git_marker" \
         $name \
         $symlink_marker \
         $symlink_target


    # Cleanup so no file_vars are carried over if
    # missing from the next file
    unset -v stat file_vars i

  done
}







