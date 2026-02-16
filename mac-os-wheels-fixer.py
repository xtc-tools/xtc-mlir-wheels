import zipfile
import os
import shutil
import tempfile
import subprocess
import pathlib
import argparse
import sys # For clean exit
from os import listdir
from os.path import isfile, join

def run_system_command(command, cwd=None):
    """Executes a system command and raises an error on failure."""
    command_str = ' '.join(str(c) for c in command)
    print(f"-> Running command: {command_str}")
    try:
        # Use subprocess.run for simplicity and good error handling
        result = subprocess.run(
            command,
            cwd=cwd,
            check=True,
            capture_output=True,
            text=True
        )
        if result.stdout:
            print(f"Command STDOUT (last 5 lines):\n{result.stdout.strip().splitlines()[-5:]}")
        
    except subprocess.CalledProcessError as e:
        print(f"Command failed (Return Code: {e.returncode}):\n{e.stderr}")
        raise
    except FileNotFoundError:
        print(f"Error: Command not found. Is '{command[0]}' in your PATH?")
        raise

def custom_wheel_modifications(extracted_dir):
    """
    Perform your specific file edits and command executions here.
    
    This is where you would put the core logic, such as:
    1. Editing configuration files.
    2. Running platform-specific tools (like install_name_tool on macOS) 
       to 'delocate' shared libraries.
    """
    
    print(f"\n--- Starting custom modifications in: {extracted_dir.name} ---")
    
    mlir_libs = extracted_dir / 'mlir/' / '_mlir_libs'
    mlir_bin = extracted_dir / 'mlir' / 'bin'
    mlir_lib = extracted_dir / 'mlir' / 'lib'

    all_bins = [join(mlir_bin, f) for f in listdir(mlir_bin) if isfile(join(mlir_bin, f))] if mlir_bin.exists() else []
    all_lib = [join(mlir_lib, f) for f in listdir(mlir_lib) if isfile(join(mlir_lib, f)) and f.endswith(".dylib")] if mlir_lib.exists() else []
    
    if mlir_libs.exists():     
        capi_dylib = pathlib.Path("python_bindings/mlir/_mlir_libs/libMLIRPythonCAPI.dylib")    
        lib_path = mlir_libs / 'libMLIRPythonCAPI.dylib'
        run_system_command(['install_name_tool', '-change', '@rpath/libLLVM.dylib', '@loader_path/../../llvm/lib/libLLVM.dylib', capi_dylib])
        run_system_command(['cp', capi_dylib, lib_path])
        
    for bin in all_bins:
        run_system_command(['install_name_tool', '-change', '@rpath/libLLVM.dylib', '@loader_path/../../llvm/lib/libLLVM.dylib', bin])
        
    for lib in all_lib:
        run_system_command(['install_name_tool', '-change', '@rpath/libLLVM.dylib', '@loader_path/../../llvm/lib/libLLVM.dylib', lib])
          
    for bin_path in all_bins:
        try:
            # We use os.chmod here to modify the file permissions
            os.chmod(bin_path, 0o755) 
            print(f"  -> Set executable permission for: {bin_path}")
        except Exception as e:
            print(f"  -> WARNING: Could not set executable permission for {bin_path}: {e}")
            
    dist_info_dir = next((d for d in extracted_dir.iterdir() if d.suffix == '.dist-info'), None)
    if dist_info_dir:
        record_file = dist_info_dir / 'RECORD'
        if record_file.exists():
            print(f"Removing old RECORD file: {record_file.name}")
            os.remove(record_file)
    
    print("--- Custom modifications finished ---")

def process_wheel(wheel_path: pathlib.Path, output_dir: pathlib.Path):
    """
    Unpacks, modifies, and repacks a wheel file.
    """
    output_dir.mkdir(parents=True, exist_ok=True)
    
    original_wheel_filename = wheel_path.name
    
    with tempfile.TemporaryDirectory() as temp_dir:
        # Create a unique directory inside temp for extraction
        extracted_dir = pathlib.Path(temp_dir) / original_wheel_filename.removesuffix('.whl')
        
        print(f"Unpacking {original_wheel_filename}...")
        try:
            with zipfile.ZipFile(wheel_path, 'r') as zip_ref:
                zip_ref.extractall(extracted_dir)
        except zipfile.BadZipFile:
            print(f"Error: {wheel_path} is not a valid ZIP file (or .whl).")
            return None
            
        # 2. Modify Files and Run Commands
        custom_wheel_modifications(extracted_dir)
        
        output_wheel_path = output_dir / original_wheel_filename

        print(f"\nRepacking and signing new wheel as: {output_wheel_path}")
        # Command: `python -m wheel pack {extracted_dir} -d {output_dir}`
        # We target the output directory, not the final file path, to allow `wheel` to control naming
        try:
            run_system_command([
                sys.executable, '-m', 'wheel', 'pack', 
                str(extracted_dir), 
                '-d', str(output_dir)
            ])
            # The 'wheel pack' command may rename the output slightly, 
            # so we check what was actually created in the output folder.
            final_wheel = next((f for f in output_dir.iterdir() if f.name.startswith(extracted_dir.name) and f.suffix == '.whl'), None)
            if final_wheel:
                # Rename the file to our desired .MODIFIED.whl name
                final_wheel.rename(output_wheel_path)
                print(f"\n✅ Successfully created modified wheel: {output_wheel_path.name}")
                return output_wheel_path
            else:
                 print("Error: Repacking seems to have failed to produce a wheel file.")
                 return None
            
        except subprocess.CalledProcessError:
            print("\n❌ Repacking failed. Ensure you have the 'wheel' package installed (`pip install wheel`).")
            return None

def main():
    """Parses arguments and runs the wheel processing logic."""
    parser = argparse.ArgumentParser(
        description="A wrapper utility to unpack, modify, and repack Python wheel files, similar to delocate-wheel.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    
    parser.add_argument(
        '--original',
        type=pathlib.Path,
        required=True,
        help="Path to the original input .whl file."
    )
    parser.add_argument(
        '--output',
        type=pathlib.Path,
        required=True,
        help="Directory where the modified .whl file will be saved."
    )
    
    args = parser.parse_args()

    # Input validation
    if not args.original.exists():
        print(f"Error: Input file not found at '{args.original}'")
        sys.exit(1)
        
    if args.original.suffix != '.whl':
        print(f"Warning: Input file '{args.original.name}' does not end with '.whl'. Proceeding anyway.")

    # Process the wheel
    try:
        process_wheel(args.original, args.output)
    except Exception as e:
        print(f"\nAn unrecoverable error occurred during processing: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
