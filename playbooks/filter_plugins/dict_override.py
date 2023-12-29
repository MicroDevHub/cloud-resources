class FilterModule(object):
  ''' Returns dictionary of items with keyed overrides that override properties with a matching selector'''
  def filters(self):
    return {
        'dict_override': dict_override
    }

def dict_override(source, overrides, selector='Type'):
    return {pk: v for k, v in overrides.items() for pk, pv in source.items() if pv.get(selector) == k}