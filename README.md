# MLIR and bindings Wheels

This is a simple project wrapper for build MLIR tools and python bindings as a python package.

The actual gitlab wheels can then be viewd from: https://gitlab.inria.fr/groups/CORSE/-/packages

## Installing the LLVM wheels for some project

The minimal required python version is: `python >= 3.10`

In a python environment setup for instance with:

    python3 -m venv .venv
    source .venv/bin/activate

One can install the mlir tools and bindings `19.1.*` with for instance:

    pip3 install mlir~=19.1.0 mlir-python-bindings~=19.1.0\
    -i https://gitlab.inria.fr/api/v4/projects/57869/packages/pypi/simple

Or on can add in a `mlir_requirements.txt` file for instance:

    --index-url https://gitlab.inria.fr/api/v4/projects/57869/packages/pypi/simple
    mlir~=19.1.0
    mlir-python-bindings~=19.1.0

And run:

    pip3 install -r mlir_requirements.txt
    ...
    Successfully installed mlir-19.1.7.2025011201+cd708029

## Using mlir installed tools

To get the path to mlir tools, for instance run `llvm-config`:

    LLVM_PREFIX=$(python -c 'import mlir;print(mlir.__path__[0])')
    $LLVM_PREFIX/bin/llvm-config --version
    19.1.7

## Maintenance

The following section if for the owners of the repository who maintain the published
packages.

### Publish new versions

Ensure that your current python version is 3.10.x, otherwise the installed packages
will not be available for this version.

Then install dependencies for the build script:

    pip install -r requirements.py

Update the version for LLVM/MLIR:
- in `llvm_revision.txt`: put the full sha1 of the new revision to publish
- in `setup.py` and in `python_bindings/setup.py`: update the variable
  `PACKAGE_VERSION = "vx.y.z.YYYMMDDHH+<sha1[:8]>"`
  where `sha1[:8]` is the first 8 bytes of the revision above, and `vx.y.z` is the
  LLVM last tag for this revision.

Then run the cibuildwheel which will create the wheels to install in `wheelhouse/`:

     ./checkout-llvm.sh
     ./build-wheels.sh
     ./build-wheels-bindings.sh

Once built, one may publish to the project repository with:

    python -m twine upload -u '<user>' -p '<token>' \
    --repository-url https://gitlab.inria.fr/api/v4/projects/57869/packages/pypi \
    wheelhouse/*.whl
