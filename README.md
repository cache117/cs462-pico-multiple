# cs462-pico-single

For verification that a ruleset works, use the following code:

    krl-compiler --verify < hello_world.krl

To add this into a pre-commit hook, use the following command in the root of the repo:

    ln -s pre-commit.sh .git/hooks/pre-commit
