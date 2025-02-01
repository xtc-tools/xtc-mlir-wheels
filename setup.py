from pathlib import Path
from setuptools import setup
from setuptools.dist import Distribution

PACKAGE_VERSION = "14.0.6.2022062201+f28c006a"

class BinaryDistribution(Distribution):
    """Distribution which always forces a binary package with platform name"""
    def has_ext_modules(foo):
        return True

if __name__ == "__main__":

    # Create an empty init.py on the fly
    with open(Path("install") / "__init__.py", "w"):
        pass

    # Create the binary distribution
    setup(
        name = "llvm",
        version = PACKAGE_VERSION,
        description = "Python packaging for llvm and llvm dev files",
        maintainer="Christophe Guillon",
        maintainer_email="christophe.guillon@inria.fr",
        requires_python = ">= 3.10",
        readme = "README.md",
        packages = ["llvm"],
        package_dir = { "llvm": "install"},
        include_package_data = True,
        distclass=BinaryDistribution,
        setup_requires = [
            "setuptools>=42",
            "wheel",
        ],
        zip_safe = False
    )
