class Solution(object):

    def containsDuplicate(self, nums):
        """
        :type nums: List[int]
        :rtype: bool
        """

        if sorted(nums) == sorted(list(set(nums))):
            return False
        else:
            return True
