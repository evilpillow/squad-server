#!/bin/bash

steam_cmd="${STEAMCMDDIR}/steamcmd.sh"

server_update_args=(+force_install_dir "${STEAMAPPDIR}" +login anonymous +app_update)

if [[ -n ${STEAM_BETA_BRANCH} ]]; then
  server_update_args+=("${STEAM_BETA_APP}" -beta "${STEAM_BETA_BRANCH}" -betapassword "${STEAM_BETA_PASSWORD}")
else
  server_update_args+=("${STEAMAPPID}")
fi

server_update_args+=(+quit)

if ! "${steam_cmd}" "${server_update_args[@]}"; then
  echo 'Failed to download server, exiting'
  exit 1
fi

# Change rcon port on first launch, because the default config overwrites the commandline parameter (you can comment this out if it has done it's purpose)
sed -i -e 's/Port=21114/'"Port=${RCONPORT}"'/g' "${STEAMAPPDIR}/SquadGame/ServerConfig/Rcon.cfg"

download_mod() {
  modid="$1"
  echo "Downloading mod '${modid}'"

  download_args=(+force_install_dir "${STEAMAPPDIR}" +login anonymous +workshop_download_item "${WORKSHOPID}" "${modid}" validate +quit)

  if "${steam_cmd}" "${download_args[@]}"; then
    printf "\nDownloaded mod\n"
  else
    printf "\nFailed to download mod, retrying\n"
    download_mod "$1"
  fi
}

ensure_mods_installed() {
  # Install mods (if defined)
  declare -a MODS="${MODS}"
  if ((${#MODS[@]})); then
    echo "Installing Mods"
    for MODID in "${MODS[@]}"; do

      download_mod "${MODID}"

      echo "Link mod content ${MODID})"
      downloaded="${STEAMAPPDIR}/steamapps/workshop/content/${WORKSHOPID}/${MODID}"
      to="${MODPATH}/${MODID}"

      if [[ -e $to ]]; then
        echo "Won't link"
      else
        ln -s "$downloaded" "$to"
        echo "Linked mod"
      fi
    done
  fi
}

if [[ -n "${IGNORE_MODS}" ]]; then
  echo "Ignoring mods"
else
  echo "Syncing mods"
  if [[ -f "${MODPATH}" ]]; then
    find "${MODPATH}"/* -maxdepth 0 -regextype posix-egrep -regex ".*/[[:digit:]]+" | xargs -0 -d"\n" rm -R 2>/dev/null
  fi
  ensure_mods_installed
fi

start_args=()

[[ -n $PORT ]] && start_args+=("Port=${PORT}")
[[ -n $QUERYPORT ]] && start_args+=("QueryPort=${QUERYPORT}")
[[ -n $RCONPORT ]] && start_args+=("RCONPORT=${RCONPORT}")
[[ -n $FIXEDMAXPLAYERS ]] && start_args+=("FIXEDMAXPLAYERS=${FIXEDMAXPLAYERS}")
[[ -n $FIXEDMAXTICKRATE ]] && start_args+=("FIXEDMAXTICKRATE=${FIXEDMAXTICKRATE}")
[[ -n $RANDOM_ARG ]] && start_args+=("RANDOM=${RANDOM_ARG}")
[[ -n $BEACONPORT ]] && start_args+=("beaconport=${BEACONPORT}")
[[ -n $FULLCRASHDUMP ]] && start_args+=("-fullcrashdump")

echo "Starting server"

"${STEAMAPPDIR}/SquadGameServer.sh" "${start_args[@]}" | dos2unix
