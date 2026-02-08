local M = {}

function M.get_test_id_by_name(node, name)
  if not node then
    return nil
  end
  local data = node:data()

  if data.type == "test" and data.name == name then
    return data.id
  end

  local children = node:children()
  if children then
    for _, child in ipairs(children) do
      local found = M.get_test_id_by_name(child, name)
      if found then
        return found
      end
    end
  end

  return nil
end

return M
