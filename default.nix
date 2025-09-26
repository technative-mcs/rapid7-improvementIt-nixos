{ pkgs ? import <nixpkgs> {} }:
let

  inherit (pkgs) stdenv;

  in
  stdenv.mkDerivation rec {
    name = "rapid7-insight-agent-${insight_agent_version}";
    insight_agent_version = "4.0.18.46";
    endpoint_broker_version = "1.8.2.0";
    bootstrap_version = "2.12.0.1";
    agent_core_version = "1.2.2.2";

    nativeBuildInputs = [ pkgs.dpkg pkgs.patchelf];

    src = ./rapid7-insight-agent_4.0.18.46-1_amd64.deb;

    unpackPhase = ''
    dpkg-deb -R $src .
    '';

    buildInputs = [ pkgs.zlib pkgs.openssl pkgs.libffi ]; # bring OpenSSL into the store

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp -r opt DEBIAN $out/

      insight_agent="$out/opt/rapid7/ir_agent/components/insight_agent/${insight_agent_version}"
      endpoint_broker="$out/opt/rapid7/ir_agent/components/endpoint_broker/${endpoint_broker_version}"
      bootstrap="$out/opt/rapid7/ir_agent/components/bootstrap/${bootstrap_version}"
      agent_core="$out/opt/rapid7/ir_agent/components/agent_core/${agent_core_version}"

      ir_agent="$insight_agent/ir_agent"

      libs="$insight_agent/lib"

      rpath="${pkgs.glibc}/lib:${pkgs.zlib.out}/lib:${pkgs.openssl.out}/lib:$libs"

      echo ">> Patch main binary"

      patchelf \
        --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        "$insight_agent"/{token_handler,connectivity_test,get_proxy}

      patchelf \
        --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        --set-rpath "$rpath" \
        "$ir_agent"

      patchelf \
        --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        "$endpoint_broker"/rapid7_endpoint_broker

      patchelf \
        --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        "$bootstrap"/{bootstrap,bootstrap_upgrader}

      patchelf \
        --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        "$agent_core"/rapid7_agent_core

      echo ">> Patch bundled .so files"
      find "$libs" -type f -name '*.so*' -exec \
      patchelf --set-rpath "$rpath" {} +

      ln -s -f $out/opt/rapid7/ir_agent/components/insight_agent/${insight_agent_version}/ir_agent $out/opt/rapid7/ir_agent/components/insight_agent/insight_agent

      cp $out/opt/rapid7/ir_agent/components/bootstrap/${bootstrap_version}/bootstrap $out/opt/rapid7/ir_agent/ir_agent

      ln -s -f $out/opt/rapid7/ir_agent/components/endpoint_broker/${endpoint_broker_version}/rapid7_endpoint_broker $out/opt/rapid7/ir_agent/components/endpoint_broker/endpoint_broker

      runHook postInstall
    '';

    meta = {
      description = "Rapid7 Insight Agent (wrapped for NixOS)";
      platforms = [ "x86_64-linux" ];
      maintainers = [ "caspersonn" ];
    };
  }
