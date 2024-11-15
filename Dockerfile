FROM cm2network/steamcmd:root

ENV HOMEDIR "/home/steam"
ENV STEAMAPPID 403240
ENV STEAMAPP squad
ENV STEAMAPPDIR "${HOMEDIR}/${STEAMAPP}-dedicated"

ENV STEAM_BETA_APP 774961
ENV STEAM_BETA_PASSWORD ""
ENV STEAM_BETA_BRANCH ""

ENV WORKSHOPID 393380
ENV MODPATH "${STEAMAPPDIR}/SquadGame/Plugins/Mods"
ENV MODS "()"

COPY entry.sh ${HOMEDIR}

RUN apt-get update && apt-get install -y dos2unix --no-install-recommends

RUN set -x \
  && mkdir -p "${STEAMAPPDIR}" \
  && chmod 755 "${HOMEDIR}/entry.sh" "${STEAMAPPDIR}" \
  && chown "${USER}:${USER}" "${HOMEDIR}/entry.sh" "${STEAMAPPDIR}"

USER ${USER}

WORKDIR ${HOMEDIR}

ENTRYPOINT ["./entry.sh"]

