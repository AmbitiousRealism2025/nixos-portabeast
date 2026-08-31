{
  lib,
  fetchFromGitHub,
  python3Packages,
}:

python3Packages.buildPythonPackage rec {
  pname = "prime-agent-runtime";
  version = "0.7.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "PrimeIntellect-ai";
    repo = "prime-agent";
    tag = "v${version}";
    hash = "sha256-rOKFkKoV2Mfg2wHioZ+2Eo3Js6C4489hxTxVu38cgbA=";
  };

  sourceRoot = "${src.name}/prime-agent-runtime";

  build-system = [ python3Packages.hatchling ];
  dependencies = with python3Packages; [
    ipykernel
    nest-asyncio
    tyro
  ];

  pythonImportsCheck = [ "rlm" ];

  meta = {
    description = "Kernel-side Python runtime for Prime Agent recursion";
    homepage = "https://github.com/PrimeIntellect-ai/prime-agent";
    license = lib.licenses.mit;
  };
}
