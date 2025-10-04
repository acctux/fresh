from pathlib import Path
import shutil
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def list_to_rel_locs_lists(source_dir: Path) -> list[Path]:
    """Return list of all files relative to source_dir."""
    return [f.relative_to(source_dir) for f in source_dir.rglob("*") if f.is_file()]


def create_backups_in_etc(source_dir: Path, etc_dir: Path, backup_suffix: str = ".bak"):
    """
    For each file in source_dir:
    - If the corresponding file exists in /etc at the same relative path,
      create a backup copy (with the given suffix).
    """
    relative_files = list_to_rel_locs_lists(source_dir)

    for rel_path in relative_files:
        etc_file = etc_dir / rel_path

        if etc_file.exists():
            backup_file = etc_file.with_suffix(etc_file.suffix + backup_suffix)
            _ = shutil.copy2(etc_file, backup_file)
            logger.info("Backup created: %s -> %s", etc_file, backup_file)
        else:
            logger.debug("No existing file to backup at: %s", etc_file)


def copy_all_to_etc(source_dir: Path, etc_dir: Path):
    """
    Copies everything from source_dir to etc_dir (/etc),
    creating directories as needed, overwriting existing files.
    """
    for source_file in source_dir.rglob("*"):
        if source_file.is_file():
            relative_path = source_file.relative_to(source_dir)
            target_file = etc_dir / relative_path

            # Create parent directories in /etc if missing
            target_file.parent.mkdir(parents=True, exist_ok=True)

            # Copy and overwrite
            _ = shutil.copy2(source_file, target_file)
            logger.info("Copied: %s -> %s", source_file, target_file)


if __name__ == "__main__":
    source = Path("/root/fresh/etc")
    dest = Path("/mnt/etc")

    create_backups_in_etc(source, dest)
    copy_all_to_etc(source, dest)
