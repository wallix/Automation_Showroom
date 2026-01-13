Role Name
=========

A role which creates users accounts into WALLIX Bastion

Requirements
------------

Fill in the users_to_create.yml file with the users details as a dictionnary. See the file for examples.

Role Variables
--------------

bastion_url: The Bastion url to reach i.e. https://bastion.lab/api keep the trailing "/api"

Dependencies
------------

api_creds.yml file
users_to_create.yml file

License
-------

BSD

Author Information
------------------

Julien Patriarca Wallix
