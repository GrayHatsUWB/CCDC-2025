# Pokepal Infrastructure Setup Instructions

The Pokepal Infrastructure is meant to be run on a Ludus environment.
Ludus information can be found [here](https://docs.ludus.cloud/docs/category/quick-start).
Make sure that you are running the latest version of Ludus.

Once the ranges are up, default creds for the boxes can be found [here](https://docs.ludus.cloud/docs/quick-start/deploy-range).

## Steps
1. Create a Ludus user specifically for the practice infrastructure boxes. Name it "PRCCDC".

2. Get the *prccdc-range-configPokePals.yml* file onto the Ludus server while logged in as user PRCCDC. 

3. Make sure all of the templates used in the yml file are built. You can check their status with

> ludus templates list

If there are templates used in the yml file that are not shown in the list command, you will need to add them. 
Additional templates can be found in the root directory of the Ludus git page [here](https://gitlab.com/badsectorlabs/ludus/-/tree/main/templates?ref_type=heads).
Add the desired template(s) with

>ludus templates add -d "template directory"

4. Make sure to add used roles used in the yml file. This can be done with

> ludus ansible role add "role"

More information can be found [here](https://docs.ludus.cloud/docs/roles)

5. Set the yml file as the current range configuration file with 

> ludus range config set -f prccdc-range-configPokePals.yml

You can check what the current config looks like with command

> ludus range config get

6. Once the correct config is set, deploy the range detailed in the yml file with

> ludus range deploy

You can check the status of the deployment with

> ludus range logs -f
>
> ludus range status

7. Ensure that all of the services (Wordpress, Confluence, etc.) are up. This can be done by checking that the correct port for the service is present in

> ss -plunt

For example, in the Wordpress box, there should be entries with the port 8080.

If the service for a specific box is not up (and the service should be set up due to a role), then use the following command to redeploy a specific box

>ludus range deploy -t user-defined-roles --limit localhost,"name of box in ProxMox"

8. Create a Ludus user specifically for the Score Engine. Name it "Scoreboard"

9. Get the *scoreboard-range-config.yml* file onto the Ludus server while logged in as user Scoreboard. 
From here, you will follow the same steps as when you set up the infrastructure range.
Set the range configuration file to the downloaded yml file and deploy it. 

> ludus range config set -f scoreboard-range-config.yml
>
> ludus range deploy

10. Download the *ScoreEngineSetup.sh* script onto the score engine debian box (.81). Run the following commands

> sudo -i
>
> chmod +x ScoreEngineSetup.sh
>
> ./ScoreEngineSetup.sh

11. Download the *event.conf* file onto the score engine box and place it in the Quotient/config/ directory.

12. Log into both of the router boxes for the infrastructure range and the scoreboard range. These boxes' IP should end in .254.
You will need to type the following commands into each router

> sudo -i
>
> iptables -I LUDUS_DEFAULTS -i ens18 -s 192.0.2."octet depends on other range subnet number" -j ACCEPT
>
> iptables-save > /etc/iptables/rules.v4

Important: You need to run the iptables commands as root (that's why you perform sudo -i).

For example, let's say the subnet of the infrastructure router is 10.3.10.### and the subnet of the scoreboard range is 10.4.10.###. (The subnet # is the second octet in the IP)
In the infrastructure router, you will run

> iptables -I LUDUS_DEFAULTS -i ens18 -s 192.0.2.104 -j ACCEPT
>
> iptables-save > /etc/iptables/rules.v4

and in the scoreboard router, you will run

> iptables -I LUDUS_DEFAULTS -i ens18 -s 192.0.2.103 -j ACCEPT
>
> iptables-save > /etc/iptables/rules.v4

13. Log into the scoreboard GUI by opening a web browser and navigating to the score engine box's IP (10.#.10.81 where # is the scoreboard range subnet number) and use the admin creds (admin,admin).

14. Add the GrayHats team by going to the Engine tab and then Team Configuration. 
When adding the team, ensure that the Team Identifier Number is the same as the range subnet number of the infrastructure range.