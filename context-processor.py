# process_context.py
import sys
import json

def process_commits(commit_list):
    """Takes a list of commit objects and modifies non-conventional ones."""
    if not commit_list:
        return []
    for commit in commit_list:
        if not commit.get('conventional', True): # Default to True if key missing
            if 'message' in commit and isinstance(commit['message'], str):
                commit['message'] = commit['message'].split('\n', 1)[0]
            if 'raw_message' in commit and isinstance(commit['raw_message'], str):
                commit['raw_message'] = commit['raw_message'].split('\n', 1)[0]
    return commit_list

def process_releases_recursively(release_data):
    """Recursively processes commits in releases and their 'previous' links."""
    if isinstance(release_data, list):
        # Handle top-level list of releases
        for release in release_data:
            process_releases_recursively(release)
    elif isinstance(release_data, dict):
        # Process commits in the current release object
        if 'commits' in release_data:
            release_data['commits'] = process_commits(release_data['commits'])
        # Recurse into the 'previous' release object
        if 'previous' in release_data and isinstance(release_data['previous'], dict):
            process_releases_recursively(release_data['previous'])
    return release_data

if __name__ == "__main__":
    try:
        # Load JSON data from standard input
        data = json.load(sys.stdin)
        # Process the data recursively
        modified_data = process_releases_recursively(data)
        # Dump the modified JSON data to standard output
        json.dump(modified_data, sys.stdout, indent=2) # Use indent=None for compact output
    except json.JSONDecodeError as e:
        print(f"Error decoding JSON: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"An error occurred: {e}", file=sys.stderr)
        sys.exit(1)

