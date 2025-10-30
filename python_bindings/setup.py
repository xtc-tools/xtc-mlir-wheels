from pathlib import Path
from setuptools import setup
from setuptools.dist import Distribution
from setuptools.command.bdist_wheel import bdist_wheel


PACKAGE_NAME = "mlir-python-bindings"
PACKAGE_VERSION = "21.1.2.2025091603+b708aea0"


class BinaryDistribution(Distribution):
    """Distribution which always forces a binary package with platform name"""
    def has_ext_modules(foo):
        return True


class CBdistWheel(bdist_wheel):
    pass


if __name__ == "__main__":

    # Create the binary distribution
    setup(
        name = PACKAGE_NAME,
        version = PACKAGE_VERSION,
        description = "Python packaging for mlir tools and mlir dev files",
        maintainer="Christophe Guillon",
        maintainer_email="christophe.guillon@inria.fr",
        python_requires = ">= 3.10",
#        packages = ["mlir"],
#        package_dir = {"": ""},
        include_package_data = True,
        distclass=BinaryDistribution,
        cmdclass={
            "bdist_wheel": CBdistWheel,
        },
        setup_requires = [
            "setuptools>=80",
        ],
        zip_safe = False
    )
