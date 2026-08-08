{
  lib,
  autoPatchelfHook,
  buildNpmPackage,
  fetchurl,
  makeBinaryWrapper,
  nodejs_22,
  primeAgentRuntime,
  python3,
  stdenv,
}:

let
  version = "0.7.1";
  buildNpmPackageNode22 = buildNpmPackage.override { nodejs = nodejs_22; };
  pythonEnv = python3.withPackages (ps: [
    ps.beautifulsoup4
    ps.dill
    ps.httpx
    ps.ipykernel
    ps.lxml
    ps.nest-asyncio
    ps.numpy
    ps.pandas
    ps.pydantic
    ps.python-dotenv
    ps.pyyaml
    ps.requests
    ps.scipy
    ps.tomli
    ps.tyro
    primeAgentRuntime
  ]);
in
buildNpmPackageNode22 {
  pname = "prime-agent";
  inherit version;

  src = fetchurl {
    url = "https://pub-728493de92a943e2a9b2d17b4719f318.r2.dev/releases/v${version}/prime-agent-${version}.tgz";
    hash = "sha256-1oYSyDI5yq+rcsx2xVrFcr/QegWeqPvSo92+HytV3Ns=";
  };
  sourceRoot = "package";

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-e06SFd9rb8BW31EOaAtDTcjjcFuwN/MBnl6w7mJvEK4=";
  npmFlags = [ "--omit=optional" ];

  postPatch = ''
    cp ${./prime-agent-package-lock.json} package-lock.json
  '';

  nativeBuildInputs = [
    autoPatchelfHook
    makeBinaryWrapper
  ];
  buildInputs = [ stdenv.cc.cc.lib ];

  dontNpmBuild = true;

  postInstall = ''
    find "$out/lib/node_modules/prime-agent/node_modules/zeromq/build" \
      -type f -name addon.node \
      ! -path '*/linux/x64/node/glibc-127-Release/addon.node' \
      -delete
  '';

  postFixup = ''
    wrapProgram "$out/bin/prime-agent" \
      --set-default PI_SKIP_VERSION_CHECK 1 \
      --set-default PRIME_AGENT_KERNEL_PYTHON ${pythonEnv}/bin/python \
      --set-default PRIME_AGENT_TELEMETRY 0
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    test "$(HOME="$TMPDIR" "$out/bin/prime-agent" --version 2>&1)" = "${version}"
    ${pythonEnv}/bin/python -c 'import IPython, bs4, dill, dotenv, httpx, ipykernel, lxml, nest_asyncio, numpy, pandas, pydantic, requests, rlm, scipy, tomli, tyro, yaml'
    runHook postInstallCheck
  '';

  meta = {
    description = "Self-improving RLM agent for coding and long-running autonomous tasks";
    homepage = "https://github.com/PrimeIntellect-ai/prime-agent";
    license = lib.licenses.mit;
    mainProgram = "prime-agent";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
