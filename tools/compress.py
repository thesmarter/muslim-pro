import os
import subprocess
import shutil

# --- CONFIGURATION ---
AUDIO_DIRECTORIES = [
    "assets/sounds/azhan",
    "assets/sounds/azkar",
    "android/app/src/main/res/raw"
]

IMAGE_DIRECTORIES = [
    "assets/images"
]

TARGET_BITRATE = "32k"  # Good balance for speech/adhan
# ---------------------

def get_file_size(path):
    return os.path.getsize(path)

def format_size(size):
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size < 1024:
            return f"{size:.2f} {unit}"
        size /= 1024

def compress_audio(file_path):
    if not file_path.lower().endswith(".mp3"):
        return False, 0, 0

    original_size = get_file_size(file_path)
    temp_path = file_path + ".tmp.mp3"

    try:
        cmd = [
            "ffmpeg", "-y", "-i", file_path, 
            "-b:a", TARGET_BITRATE, 
            "-map_metadata", "0",
            temp_path
        ]
        
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        
        if result.returncode != 0:
            return False, 0, 0

        new_size = get_file_size(temp_path)
        
        if new_size < original_size:
            shutil.move(temp_path, file_path)
            return True, original_size, new_size
        else:
            os.remove(temp_path)
            return False, original_size, original_size
    except Exception:
        return False, 0, 0

def compress_image(file_path):
    ext = file_path.lower().split('.')[-1]
    if ext not in ["png", "jpg", "jpeg"]:
        return False, 0, 0

    original_size = get_file_size(file_path)
    temp_path = file_path + ".tmp." + ext

    try:
        # Use ffmpeg for basic image compression
        # For PNG: -compression_level 9
        # For JPG: -q:v 2 (higher quality, smaller size than default often)
        if ext == "png":
            cmd = ["ffmpeg", "-y", "-i", file_path, "-compression_level", "9", temp_path]
        else:
            cmd = ["ffmpeg", "-y", "-i", file_path, "-q:v", "5", temp_path]
            
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        
        if result.returncode != 0:
            if os.path.exists(temp_path): os.remove(temp_path)
            return False, 0, 0

        new_size = get_file_size(temp_path)
        if new_size < original_size:
            shutil.move(temp_path, file_path)
            return True, original_size, new_size
        else:
            os.remove(temp_path)
            return False, original_size, original_size
    except Exception:
        return False, 0, 0

def main():
    print("🚀 Starting Comprehensive Project Compression...")
    
    total_original = 0
    total_new = 0
    files_processed = 0

    # 1. Audio Compression
    print("\n🎧 Compressing Audio Files...")
    for directory in AUDIO_DIRECTORIES:
        if not os.path.exists(directory): continue
        print(f"  📂 Processing Audio: {directory}")
        for filename in os.listdir(directory):
            file_path = os.path.join(directory, filename)
            if os.path.isfile(file_path) and filename.lower().endswith(".mp3"):
                success, old_sz, new_sz = compress_audio(file_path)
                if success:
                    total_original += old_sz
                    total_new += new_sz
                    files_processed += 1
                    print(f"    ✅ {filename}: {format_size(old_sz)} -> {format_size(new_sz)}")
                else:
                    total_original += old_sz
                    total_new += old_sz

    # 2. Image Compression
    print("\n🖼️ Compressing Image Files...")
    for directory in IMAGE_DIRECTORIES:
        if not os.path.exists(directory): continue
        print(f"  📂 Processing Images: {directory}")
        for filename in os.listdir(directory):
            file_path = os.path.join(directory, filename)
            if os.path.isfile(file_path):
                success, old_sz, new_sz = compress_image(file_path)
                if success:
                    total_original += old_sz
                    total_new += new_sz
                    files_processed += 1
                    print(f"    ✅ {filename}: {format_size(old_sz)} -> {format_size(new_sz)}")
                else:
                    total_original += old_sz
                    total_new += old_sz

    # 2. Summary
    if files_processed > 0:
        saved = total_original - total_new
        reduction_pct = (saved / total_original * 100) if total_original > 0 else 0
        print(f"\n🎉 Done! Processed {files_processed} audio files.")
        print(f"📊 Total Size Reduction: {format_size(total_original)} -> {format_size(total_new)}")
        print(f"📉 Total Saved: {format_size(saved)} (-{reduction_pct:.1f}%)")
    else:
        print("\nℹ️ No files were compressed.")

    print("\n💡 Tip: For further reduction, consider using Android App Bundle (.aab) and enabling R8 shrinking in build.gradle.")

if __name__ == "__main__":
    main()
