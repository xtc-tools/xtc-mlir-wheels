from pathlib import Path
from setuptools import setup
from setuptools.dist import Distribution
from setuptools.command.bdist_wheel import bdist_wheel


PACKAGE_VERSION = "19.1.7.2025011201+cd708029"


class BinaryDistribution(Distribution):
    """Distribution which always forces a binary package with platform name"""
    def has_ext_modules(foo):
        return True


class CBdistWheel(bdist_wheel):
    def get_tag(self):
        python, abi, plat = super().get_tag()
        # Force python and abi to generic python3
        return "py3", "none", plat


if __name__ == "__main__":

    # Make it a package
    with open(Path("install") / "__init__.py", "w"):
        pass

    # Create the binary distribution
    setup(
        name = "llvm",
        version = PACKAGE_VERSION,
        description = "Python packaging for llvm and llvm dev files",
        maintainer="Christophe Guillon",
        maintainer_email="christophe.guillon@inria.fr",
        python_requires = ">= 3.10",
        packages = ["llvm"],
        package_dir = {"llvm": "install"},
        include_package_data = True,
        distclass=BinaryDistribution,
        cmdclass={
            "bdist_wheel": CBdistWheel,
        },
        setup_requires = [
            "setuptools>=42",
        ],
        zip_safe = False
    )
