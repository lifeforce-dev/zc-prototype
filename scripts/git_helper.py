import os
import subprocess

class GitHelper:
    @staticmethod
    def does_repo_exist(repo_path):
        """Check if the path is a valid Git repository."""
        if not os.path.exists(repo_path):
            return False

        git_dir = os.path.join(repo_path, '.git')
        return os.path.isdir(git_dir)

    @staticmethod
    def run_git_command(repo_path, command):
        """Run a git command in the given repository path and return the output."""
        try:
            print (f"running git command{command}")
            result = subprocess.run(
                ["git"] + command,
                cwd=repo_path,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            print (f"done running git command{command}")
            return result.stdout
        except subprocess.CalledProcessError as e:
            print(f"Error running git command: {e.stderr}")
            return None

    @staticmethod
    def clone(repo_path, repo_url):
        """Clone a repository into the given path."""
        if not os.path.exists(repo_path):
            os.makedirs(repo_path, exist_ok=True)
        return GitHelper.run_git_command(repo_path, ["clone", repo_url, repo_path])

    @staticmethod
    def fetch(repo_path):
        """Fetch updates from the remote repository."""
        return GitHelper.run_git_command(repo_path, ["fetch"])

    @staticmethod
    def checkout(repo_path, branch):
        """Checkout a specific branch in the given repository."""
        return GitHelper.run_git_command(repo_path, ["checkout", branch])

    @staticmethod
    def reset_hard(repo_path):
        """Reset the given repository to the last commit, discarding all changes."""
        return GitHelper.run_git_command(repo_path, ["reset", "--hard"])

    @staticmethod
    def pull(repo_path):
        """Pull updates from the remote repository into the given path."""
        return GitHelper.run_git_command(repo_path, ["pull"])

    @staticmethod
    def is_correct_version(repo_path, version):
        current_commit = GitHelper.run_git_command(repo_path, ["rev-parse", "HEAD"]).strip()
        is_at_commit = current_commit.startswith(version)

        current_branch = GitHelper.run_git_command(repo_path, ["rev-parse", "--abbrev-ref", "HEAD"]).strip()
        is_at_branch = current_branch == version

        current_tag = GitHelper.run_git_command(repo_path, ["describe", "--tags", "--exact-match"])
        if current_tag:
            current_tag = current_tag.strip()
            is_at_tag = current_tag == version
        else:
            is_at_tag = False

        is_valid = is_at_commit or is_at_branch or is_at_tag
        print(f"Version={version} CurrentBranch={current_branch}"
              f" CurrentCommit={current_commit} CurrentTag={current_tag}"
              f" IsCorrectVersion={is_valid}")
        return is_valid