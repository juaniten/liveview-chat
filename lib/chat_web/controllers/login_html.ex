defmodule ChatWeb.LoginHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use ChatWeb, :html
  import ChatWeb.CoreComponents

  embed_templates "login_html/*"
end
