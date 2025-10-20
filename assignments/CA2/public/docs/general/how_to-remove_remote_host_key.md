# How to remove remote host key

## When

```bash
loe@Cobblestone:~$ ssh 172.22.0.200
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
The fingerprint for the ED25519 key sent by the remote host is
SHA256:4nGhY8hRS7F1JUW7NF0/98yG1Sz/0726EWncvn6/PzQ.
Please contact your system administrator.
Add correct host key in /home/loe/.ssh/known_hosts to get rid of this message.
Offending RSA key in /home/loe/.ssh/known_hosts:255
Host key for 172.22.0.200 has changed and you have requested strict checking.
Host key verification failed.
```

## How

`ssh-keygen -R hostname/IP`
