-- Custom opener for blade views
local M = {}

local ts = vim.treesitter
local ts_utils = require("nvim-treesitter.ts_utils")

local function ascend_to_parent_node(node)
  if node and node:type() == "string_content" then
    return node:parent():parent():parent()
  end
  return node
end

local function get_function_name(node)
  if node:type() == "function_call_expression" then
    return ts.get_node_text(node:named_child(0), 0)
  end

  if node:type() == "scoped_call_expression" then
    local scope = ts.get_node_text(node:named_child(0), 0)
    local name = ts.get_node_text(node:named_child(1), 0)
    return scope .. "::" .. name
  end
end

local function view_name(arguments_node, index)
  if arguments_node then
    local first_argument_node = arguments_node:named_child(index)
    if first_argument_node then
      local name = ts.get_node_text(first_argument_node, 0):gsub("^['\"]", ""):gsub("['\"]$", ""):gsub("%.", "/")
      return name .. ".blade.php"
    end
  end
end

local function get_name_info(name)
  local names = {
    view = { position = 1, index = 0 },
    ["View::make"] = { position = 2, index = 0 },
    ["Route::view"] = { position = 2, index = 1 },
  }
  return names[name]
end

local function find_view_name(node)
  while node do
    local function_name = get_function_name(node)
    local name_info = get_name_info(function_name)
    if name_info then
      local argument_node = node:named_child(name_info.position)
      return view_name(argument_node, name_info.index)
    end
    node = node:parent()
  end
end

function M.get_view_name()
  local node = ascend_to_parent_node(ts_utils.get_node_at_cursor())
  return find_view_name(node)
end

function M.gf()
  local view = M.get_view_name()

  if not view then
    return
  end

  local dot_git_path = vim.fn.finddir(".git", ".;")
  dot_git_path = vim.fn.fnamemodify(dot_git_path, ":h")
  if dot_git_path:sub(1, 1) == "." then
    dot_git_path = ""
  else
    dot_git_path = dot_git_path .. "/"
  end

  vim.cmd("edit " .. dot_git_path .. "resources/views/" .. view)
  return true
end

return M
