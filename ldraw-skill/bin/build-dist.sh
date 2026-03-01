#!/bin/bash

source "$(dirname "$0")/../include/dirs.inc.sh"

skill_md="$__base_dir/SKILL.md"
license_txt="$__base_dir/LICENSE.txt"
annotated_ref_md="$__base_dir/ANNOTATED_REFERENCE.md"
requirements_txt="$__base_dir/requirements.txt"

ldraw_specs="$ldraw_grammars_dir/specs/ldraw-specs.md"

ldraw_lark_grammar="$ldraw_lark_dir/grammars/ldraw.lark"

ldraw_parser="$ldraw_parser_dir/ldrawparser.py"
ldraw_math="$ldraw_parser_dir/ldrawmath.py"

ldraw_model_parser="$ldraw_tools_dir/ldraw_parse_model.py"
ldraw_validator="$ldraw_tools_dir/ldraw-validator.py"
ldraw_annotator="$ldraw_tools_dir/ldraw-annotate-models.py"
ldraw_contacts="$ldraw_tools_dir/ldraw_contacts.py"
ldraw_collisions="$ldraw_tools_dir/ldraw_collisions.py"

ldraw_query_db="$ldraw_tools_dir/ldraw-query-db.py"

ldraw_db="$1"
ldraw_models_dir="$2"

if [[ -z "$ldraw_db" || -z "$ldraw_models_dir" ]]; then
    echo "Usage: $0 <ldraw-db-to-include> <ldraw-models-dir-to-include>"
    exit 1
fi

[ ! -f "$ldraw_db" ] && { echo "[ERROR] LDraw database file not found: $ldraw_db"; exit 1; }
[ ! -d "$ldraw_models_dir" ] && { echo "[ERROR] LDraw models directory not found: $ldraw_models_dir"; exit 1; }

echo "[INFO] Building skill distribution package (zip)..."

# Ask before overwriting scripts/ and references/ if they already exist
if [ -d "$scripts_dir" ] || [ -d "$references_dir" ]; then
    read -p "Warning: $scripts_dir or $references_dir already exists. Do you want to overwrite them? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborting build to avoid overwriting existing files."
        exit 1
    else
        echo "Overwriting existing $scripts_dir and $references_dir..."
        rm -rf "$scripts_dir" "$references_dir"
    fi
fi

mkdir -p $references_dir/models
mkdir -p $scripts_dir

# Skill and license files
cp "$skill_md" "$skill_builder_dir/"
cp "$license_txt" "$skill_builder_dir/"

# Copy LDraw database and models
cp "$ldraw_db" "$scripts_dir/ldraw.db"
# models will go on the skills dir, zipped to get a smaller zip file and then instruct Claude to download them separately from github
mkdir -p "$__base_dir/models"
cp -r "$ldraw_models_dir"/* "$__base_dir/models/"

rm "$__base_dir/models.zip"

# Compress the models directory, no parents, to get a smaller zip file and then instruct Claude to download them separately from github
zip -r "$__base_dir/models.zip" "$__base_dir/models" -j || {
    echo "[ERROR] Failed to create models zip package"
    exit 1
}

rm -rf "$__base_dir/models"

# Copy required scripts and tools
cp "$ldraw_parser" "$scripts_dir/"
cp "$ldraw_math" "$scripts_dir/"

cp "$ldraw_model_parser" "$scripts_dir/"
cp "$ldraw_validator" "$scripts_dir/"
cp "$ldraw_annotator" "$scripts_dir/"
cp "$ldraw_contacts" "$scripts_dir/"
cp "$ldraw_collisions" "$scripts_dir/"
cp "$ldraw_query_db" "$scripts_dir/"

# Copy additional resources if needed (e.g., grammars, specs)
cp "$ldraw_lark_grammar" "$references_dir/"
cp "$ldraw_specs" "$references_dir/"
cp "$annotated_ref_md" "$references_dir/"
cp "$requirements_txt" "$scripts_dir/"

# Now, reduce size even more by compressing the models directory and also the database file

# zip including directory: $dist_dir/ldraw-skill-builder -> $dist_dir/ldraw-skill-builder-YYYY-MM-DD-hh-mm-ss.zip
output_zip="$dist_dir/ldraw-skill-builder-$(date +%F-%H-%M-%S).zip"
cd "$dist_dir" || { echo "[ERROR] Could not change directory to $dist_dir"; exit 1; }

zip -r "$output_zip" "ldraw-skill-builder" || {
    echo "[ERROR] Failed to create zip package $output_zip"
    exit 1
}

echo "[INFO] Skill distribution package created at: $output_zip"
