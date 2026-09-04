# Connect from an iPhone with Termius

Complete the VPS setup from a Mac first. The phone uses the same server account and attaches to the same tmux sessions.

## Add the SSH key

In Termius on the iPhone:

1. Open **Keychain** and add or generate an Ed25519 key.
2. If it is a new key, copy its public key only.
3. From an already trusted Mac session, add that public key as one line in `~/.ssh/authorized_keys` on the VPS.
4. Keep the private key in Termius; never copy it into the Hatchery repository.

Confirm the `.ssh` permissions on the VPS if authentication is rejected:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

## Add and connect to the host

In Termius, create a host with:

- **Address:** the VPS hostname or IP address
- **Port:** `22`, unless you deliberately configured another SSH port
- **Username:** the same non-root user used during setup
- **Key:** the matching private key from Termius Keychain

Open the host and accept its host-key fingerprint only after comparing it with the fingerprint shown by your provider or a trusted existing connection.

## Use persistent sessions

List sessions after connecting:

```bash
tmux ls
```

Attach to an existing agent session:

```bash
tmux attach -t codex
# or
tmux attach -t hermes
```

Create it if it does not exist:

```bash
tmux new -s codex
# or
tmux new -s hermes
```

To detach while leaving the agent running, press `Ctrl+b`, release both keys, then press `d`.

If the phone changes networks or sleeps, the SSH connection may close but tmux keeps the remote session alive. Reopen the Termius host, run `tmux ls`, and attach again.
