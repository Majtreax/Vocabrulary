import sys
import json
import pandas as pd
from transliterate import translit

# --- CONFIGURATION ---
FILES = {
    "words": "words.csv",
    "translations": "translations.csv",
    "output": "dictionary.json"
}

# Strictly defines the column order for the JSON output.
OUTPUT_ORDER = [
    'id',
    'word',
    'word_translit',
    'word_en',
    'type',
    'level',
    'sentence',
    'sentence_translit',
    'sentence_en',
]

def get_transliteration(text):
    """
    Safely transliterates Russian Cyrillic to Latin characters.
    Returns an empty string if the input is not a valid string.
    """
    if not isinstance(text, str) or not text.strip():
        return ""
    try:
        return translit(text, 'ru', reversed=True)
    except Exception:
        # Fallback to original text if transliteration fails
        return text

def process_vocabulary():
    print(f"\n{'='*30}")
    print("   Vocabulary Data Compiler")
    print(f"{'='*30}\n")

    # --- 1. Load Primary Vocabulary ---
    print(f"Reading vocabulary source: {FILES['words']}...")
    try:
        df_words = pd.read_csv(FILES['words'])
        
        # Filter for only the columns we intend to keep from the source
        target_cols = ['id', 'bare', 'type', 'level']
        available_cols = [c for c in target_cols if c in df_words.columns]
        df_words = df_words[available_cols]
        
    except FileNotFoundError:
        print(f"Error: Required file '{FILES['words']}' is missing.")
        sys.exit(1)

    # --- 2. Load and Aggregate Translations ---
    print(f"Reading translations: {FILES['translations']}...")
    try:
        df_trans = pd.read_csv(FILES['translations'])
        
        # Filter strictly for English translations
        if 'lang' in df_trans.columns:
            df_trans = df_trans[df_trans['lang'] == 'en']

        # Group definitions by 'word_id'. 
        # This condenses multiple meanings into a single string and grabs the first example sentence.
        trans_grouped = df_trans.groupby('word_id').agg({
            'tl': lambda x: '; '.join(x.dropna().astype(str).unique()),
            'example_ru': 'first',
            'example_tl': 'first'
        }).reset_index()

    except FileNotFoundError:
        print(f"Error: Required file '{FILES['translations']}' is missing.")
        sys.exit(1)

    # --- 3. Merge and Normalize ---
    print("Merging datasets and standardizing columns...")
    df_merged = pd.merge(
        df_words, 
        trans_grouped, 
        left_on='id', 
        right_on='word_id', 
        how='left'
    )
    
    # Rename columns to match the target schema
    df_merged.rename(columns={
        'bare': 'word',
        'tl': 'word_en',
        'example_ru': 'sentence',
        'example_tl': 'sentence_en'
    }, inplace=True)

    # Handle missing values for string columns to avoid "NaN" in JSON
    text_cols = ['word', 'word_en', 'type', 'level', 'sentence', 'sentence_en']
    for col in text_cols:
        if col in df_merged.columns:
            df_merged[col] = df_merged[col].fillna('')

    # --- 4. Transliteration ---
    print("Generating Cyrillic-to-Latin transliterations...")
    df_merged['word_translit'] = df_merged['word'].apply(get_transliteration)
    df_merged['sentence_translit'] = df_merged['sentence'].apply(get_transliteration)

    # --- 5. Export ---
    print(f"Serializing output to {FILES['output']}...")
    
    # Select only the columns defined in OUTPUT_ORDER, ensuring exact output structure
    final_cols = [c for c in OUTPUT_ORDER if c in df_merged.columns]
    df_final = df_merged[final_cols]
    
    try:
        json_data = df_final.to_dict(orient='records')
        
        with open(FILES['output'], 'w', encoding='utf-8') as f:
            # ensure_ascii=False ensures Cyrillic characters are readable in the file
            json.dump(json_data, f, ensure_ascii=False, indent=2)
            
        print(f"\nBuild complete.\n{len(json_data):,} Unique words written to the json.")
        
    except Exception as e:
        print(f"Critical Error: Failed to write JSON file. {e}")
        sys.exit(1)

if __name__ == "__main__":
    process_vocabulary()
    
