# MLIR and bindings Wheels

This is a simple project wrapper for build MLIR tools, dev files and python bindings as a python package.

The built packagea are vailable on PyPI as:
- xtc-mlir-tools: MLIR bnary tools and shared object;
- xtc-mlir-dev: development files, includes, archives and cmake recipes;
- xtc-mlir-python-bindings: MLIR python bindings.

## Installing the MLIR wheels for some project

The minimal required python version is: `python >= 3.10`

In a python environment setup for instance with:

    python3 -m venv .venv
    source .venv/bin/activate

One can install the mlir tools and bindings `19.1.*` with for instance:

    pip3 install xtc-mlir-tools~=21.1.2.0 xtc-mlir-python-bindings~=21.1.2.0

Or on can add in a `mlir_requirements.txt` file for instance:

    xtc-mlir-tools~=21.1.2.0
    xtc-mlir-python-bindings~=21.1.2.0

And run:

    pip3 install -r mlir_requirements.txt
    ...
    Successfully installed xtc-mlir-tools-21.1.2.5
    Successfully installed xtc-mlir-python-bindings-21.1.2.5

## Using MLIR installed tools

To get the path to mlir tools, for instance run `mlir-opt`:

    MLIR_PREFIX=$(python -c 'import mlir;print(mlir.__path__[0])')
    $MLIR_PREFIX/bin/mlir-opt --version
    21.1.2.5

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
- in `version.txt`: update content to `x.y.z.X`
  where `x.y.z` is the LLVM last tag for this revision and X is a unique incremental
  id for this package version starting a 1 for each new LLVM revision.

Then run the cibuildwheel which will create the wheels to install in `wheelhouse/`:

     ./checkout-llvm.sh
     ./build-wheels-tools.sh
     ./build-wheels-dev.sh
     ./build-wheels-bindings.sh

Once built, one may publish to the project repository with (here to TestPyPI):

    python -m twine upload -u '<user>' -p '<token>' \
    -r https://test.pypi.org/legacy \
    wheelhouse/*.whl
