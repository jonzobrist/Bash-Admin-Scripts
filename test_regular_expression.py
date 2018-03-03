# This Python function helps you to test arbitrary regular expressions
#
# Usage:
# Import into python/ipython/script
# Pass in your regular expression as a string or regular expression r'string'
#
# Often times when writing regular expressions
# I find myself manually iterating over the pattern
# testing a string it failed to match to see where
# the problem is
# I wrote this to do that automatically
# You give it a string or r'string' pattern and a line to test
# it against. It slices the pattern, ignores patterns that fail
# to compile into a regex as invalid patterns
# any valid patterns are tested against the test line
# Passes are reported via printing, failure causes the function
# to return the current expression string
# This is the regex that compiled but failed to match
# 
import re


def test_re(my_pattern, test_line):
    """ Given regular expression pattern
    slice it and find where it's breaking
    check test_line and find matches
    """
    for cur_pos in range(1, len(my_pattern)):
        pat_slice = my_pattern[0:cur_pos]
        try:
            my_re = re.compile(pat_slice)
            print("{}".format(cur_pos))
            matches = my_re.findall(test_line)
            if len(matches) == 0:
                return my_pattern[0:cur_pos]
            else:
                print("Pass {}".format(matches))
        except:
            next
