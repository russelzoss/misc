#!/usr/bin/env python

import re

log = "test-sample.log"
prog = re.compile(".*\s<=\s.*\sid=(?P<msg_id>.*\s+).*T=\"(?P<subject>.*)\".*")


with open(log) as f:
    for line in f:
        match = prog.match(line)
        if match:
           print('ID: {:<50} Subject: {}'.format(match.group('msg_id'), match.group('subject')))
