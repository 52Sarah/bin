import sublime_plugin
import os


def _show_name(name):
    return ([os.path.basename(name), name] if name
            else ["untitled", "untitled"])


class ShowBuffersCommand(sublime_plugin.WindowCommand):
    def run(self):
        window = self.window
        views = list(window.views())
        show_entries = [_show_name(v.file_name()) for v in views]

        def on_done(index):
            if index == -1:
                return
            window.focus_view(views[index])

        window.show_quick_panel(show_entries, on_done)