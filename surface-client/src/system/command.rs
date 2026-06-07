use std::process::Command;

pub fn command_output(command: &str, args: &[&str]) -> Result<String, String> {
    let output = Command::new(command)
        .args(args)
        .output()
        .map_err(|err| err.to_string())?;

    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
    } else {
        Err(String::from_utf8_lossy(&output.stderr).trim().to_string())
    }
}

pub fn command_success(command: &str, args: &[&str]) -> bool {
    Command::new(command)
        .args(args)
        .status()
        .is_ok_and(|status| status.success())
}

pub fn run_command(mut command: Command) -> Result<(), String> {
    let output = command.output().map_err(|err| err.to_string())?;
    if output.status.success() {
        Ok(())
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
        Err(if stderr.is_empty() {
            "commande échouée".to_string()
        } else {
            stderr
        })
    }
}
