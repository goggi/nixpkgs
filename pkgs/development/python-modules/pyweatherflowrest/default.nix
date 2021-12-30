{ lib
, aiohttp
, buildPythonPackage
, fetchFromGitHub
, pythonOlder
}:

buildPythonPackage rec {
  pname = "pyweatherflowrest";
  version = "1.0.0";
  format = "pyproject";

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "briis";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-LS7vwQQBCVwi098aJd8ZSkEEwZKL1bikvAvjH+XHaok=";
  };

  propagatedBuildInputs = [
    aiohttp
  ];

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace "--cov=pyweatherflowrest --cov-append" ""
  '';

  # Module has no tests. test.py is a demo script
  doCheck = false;

  pythonImportsCheck = [
    "pyweatherflowrest"
  ];

  meta = with lib; {
    description = "Python module to get data from WeatherFlow Weather Stations";
    homepage = "https://github.com/briis/pyweatherflowrest";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ fab ];
  };
}
