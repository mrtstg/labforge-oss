#!/bin/bash
COPYRIGHT="Copyright (C) 2025 Ilya Zamaratskikh"
FULL_COPYRIGHT="{- Copyright (C) 2025 Ilya Zamaratskikh\n\nThis program is free software; you can redistribute it and/or modify\nit under the terms of the GNU General Public License as published by\nthe Free Software Foundation; either version 3 of the License, or\n(at your option) any later version.\n\nThis program is distributed in the hope that it will be useful,\nbut WITHOUT ANY WARRANTY; without even the implied warranty of\nMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\nGNU General Public License for more details.\n\nYou should have received a copy of the GNU General Public License\nalong with this program; if not, see <http://www.gnu.org/licenses>. -}"
files=$(find ./ -name "*.hs" -not -path '*/.stack-work/*' -not -name "Setup.hs" -not -path '*/api-common/*' -not -path '*/proxmox-api/*' -not -path '*/keycloak-api/*' -not -path '*/redis-utils/*' -not -path '*/proxmox-fs-agent/*' 2> /dev/null)
for file in $files; do
    head -n 1 $file | grep "$COPYRIGHT" &> /dev/null
    if [[ $? -eq 1 ]]; then
        echo $file
        if [[ $1 == "-a" ]]; then
            touch /tmp/tmpfile
            echo -e $FULL_COPYRIGHT > /tmp/tmpfile
            cat $file >> /tmp/tmpfile
            cp /tmp/tmpfile $file
            rm /tmp/tmpfile
        fi
    fi
done
