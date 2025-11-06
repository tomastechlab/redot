#!/bin/bash

add_file() {
    local original_path="$1"
    
    # Validate file exists
    if [[ ! -f "$original_path" ]]; then
        echo "Error: File $original_path does not exist"
        return 1
    fi
    
    # Get absolute path
    local abs_original_path=$(realpath "$original_path")
    
    # Generate store path (using basename with timestamp for uniqueness)
    local filename=$(basename "$abs_original_path")
    local store_path="$STORE_DIR/$filename"
    
    # Create store directory if needed
    mkdir -p "$STORE_DIR"
    
    # Check if file already tracked
    if grep -q "^$abs_original_path;" "$DATABASE_FILE" 2>/dev/null; then
        echo "Error: File $abs_original_path is already tracked"
        return 1
    fi
    
    # Move original file to store
    echo "Moving $abs_original_path to store..."
    mv "$abs_original_path" "$store_path"
    
    # Create symlink in original location
    echo "Creating symlink at $abs_original_path"
    ln -sf "$store_path" "$abs_original_path"
    
    # Calculate checksum
    local checksum=$(md5sum "$store_path" | cut -d' ' -f1)
    
    # Store in database
    echo "$abs_original_path;$store_path;$checksum;file" >> "$DATABASE_FILE"
    
    echo "Added $abs_original_path to tracking"
}

update_files() {
    local temp_db=$(mktemp)
    local changes_detected=false
    
    while IFS=';' read -r original_path store_path checksum file_type; do
        # Skip empty lines
        [[ -z "$original_path" ]] && continue
        
        # Check if symlink still exists at original location
        if [[ -L "$original_path" ]]; then
            # Get the target of the symlink
            local symlink_target=$(readlink "$original_path")
            
            # Verify it points to our store
            if [[ "$symlink_target" == "$store_path" ]]; then
                # Check if file has changed
                if [[ -f "$store_path" ]]; then
                    local current_checksum=$(md5sum "$store_path" | cut -d' ' -f1)
                    
                    if [[ "$current_checksum" != "$checksum" ]]; then
                        echo "File $original_path has changed, updating..."
                        changes_detected=true
                        
                        # Move the new version to store (overwriting old one)
                        # This assumes we want to track the new version
                        # In practice, you might want to handle this differently
                        # For now, we'll just update the checksum
                    fi
                fi
            fi
        else
            echo "Warning: $original_path is not a symlink or doesn't exist"
        fi
        
        echo "$original_path;$store_path;$checksum;$file_type" >> "$temp_db"
    done < "$DATABASE_FILE"
    
    # Replace database with updated version
    mv "$temp_db" "$DATABASE_FILE"
    
    if [[ "$changes_detected" == true ]]; then
        echo "Update complete - changes detected"
    else
        echo "No changes detected"
    fi
}

restore_files() {
    # Read database in reverse order to handle parent directory creation properly
    while IFS=';' read -r original_path store_path checksum file_type; do
        # Skip empty lines
        [[ -z "$original_path" ]] && continue
        
        # Ensure parent directory exists
        local parent_dir=$(dirname "$original_path")
        mkdir -p "$parent_dir"
        
        # Remove existing symlink or file if it exists
        if [[ -L "$original_path" ]] || [[ -f "$original_path" ]]; then
            rm -f "$original_path"
        fi
        
        # Check if the file exists in store
        if [[ -f "$store_path" ]]; then
            # Move file from store back to original location
            echo "Restoring $original_path from store..."
            mv "$store_path" "$original_path"
            
            # Set proper permissions (optional)
            chmod --reference="$store_path" "$original_path" 2>/dev/null || true
        else
            echo "Warning: File not found in store: $store_path"
        fi
    done < "$DATABASE_FILE"
    
    echo "Restore complete"
}

list_files() {
    echo "Tracked files:"
    while IFS=';' read -r original_path store_path checksum file_type; do
        [[ -z "$original_path" ]] && continue
        echo "  $original_path -> $store_path"
    done < "$DATABASE_FILE"
}

git_sync() {
    cd "$HOME/redot"
    git add .
    git commit -m "Update: $(date)"
    git push origin main
}

# Load configuration
source "$HOME/redot/config/config"

# Command dispatch
case "$1" in
    add) add_file "$2" ;;
    update) update_files ;;
    restore) restore_files ;;
    list) list_files ;;
	sync) git_sync ;;
    *) echo "Invalid command" ;;
esac
    *) echo "Usage: dotfiles [add|update|restore|list]" ;;
esac

