# LLVM Wheels

This is a simple project wrapper for build LLVM libraries as a python package.

The actual gitlab wheels can then be viewd from: https://gitlab.inria.fr/groups/CORSE/-/packages

## Installing the LLVM wheels for some project

The minimal required python version is: `python >= 3.10`

In a python environment setup for instance with:

    python3 -m venv .venv
    source .venv/bin/activate

One can install the llvm libraries `14.0.*` with for instance:

    pip3 install llvm~=14.0.0 \
    -i https://gitlab.inria.fr/api/v4/projects/57611/packages/pypi/simple

Or on can add in a `llvm_requirements.txt` file for instance:

    --extra-index-url https://gitlab.inria.fr/api/v4/projects/57611/packages/pypi/simple
    llvm~=14.0.0

And run:

    pip3 install -r llvm_requirements.txt
    ...
    Successfully installed llvm-14.0.6.2022062201+f28c006a

## Using llvm installed tools

To get the path to llvm tools, for instance run `llvm-config`:

    LLVM_PREFIX=$(python -c 'import llvm;print(llvm.__path__[0])')
    $LLVM_PREFIX/bin/llvm-config --version
    14.0.6

## Maintenance

The following section if for the owners of the repository who maintain the published
packages.

### Publish new versions

Ensure that your current python version is 3.10.x, otherwise the installed packages
will not be available for this version.

Then install dependencies for the build script:

    pip install -r requirements.py

Update the version for LLVM:
- in `llvm_revision.txt`: put the full sha1 of the new revision to publish
- in `setup.py`: update the variable `PACKAGE_VERSION = "vx.y.z.YYYMMDDHH+<sha1[:8]>"`
  where `sha1[:8]` is the first 8 bytes of the revision above, and `vx.y.z` is the
  LLVM last tag for this revision.

Then run the cibuildwheel which will create the wheels to install in `wheelhouse/`:

     ./checkout-llvm.sh
     ./build-wheels.sh

Once built, one may publish to the project repository with:

    python -m twine upload -u '<user>' -p '<token>' \
    --repository-url https://gitlab.inria.fr/api/v4/projects/57611/packages/pypi \
    wheelhouse/*.whl
