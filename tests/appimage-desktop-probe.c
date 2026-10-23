#include <gio/gio.h>
#include <gtk/gtk.h>

/* Exercise the paths that SDL's dummy driver never reaches. */
int main(int argc, char **argv) {
    if (argc != 2)
        return 2;
    GError *error = NULL;
    gtk_init(&argc, &argv);
    GVfs *vfs = g_vfs_get_default();
    g_print("VFS: %s\n", G_OBJECT_TYPE_NAME(vfs));
    if (g_strcmp0(G_OBJECT_TYPE_NAME(vfs), "GDaemonVfs") != 0)
        return 1;
    GFile *trash = g_file_new_for_uri("trash:///");
    GFileInfo *info = g_file_query_info(trash, G_FILE_ATTRIBUTE_STANDARD_TYPE,
                                      G_FILE_QUERY_INFO_NONE, NULL, &error);
    if (!info) {
        g_printerr("GVfs: %s\n", error->message);
        return 1;
    }
    g_object_unref(info);
    g_object_unref(trash);
    GdkPixbuf *svg = gdk_pixbuf_new_from_file(argv[1], &error);
    if (!svg) {
        g_printerr("SVG: %s\n", error->message);
        return 1;
    }
    g_object_unref(svg);
    GdkPixbuf *icon = gtk_icon_theme_load_icon(gtk_icon_theme_get_default(),
                                              "image-missing", 32, 0, &error);
    if (!icon) {
        g_printerr("Icon: %s\n", error->message);
        return 1;
    }
    g_object_unref(icon);
    GtkWidget *dialog = gtk_file_chooser_dialog_new("AppImage regression", NULL,
        GTK_FILE_CHOOSER_ACTION_OPEN, "Cancel", GTK_RESPONSE_CANCEL, NULL);
    gtk_widget_show_all(dialog);
    gtk_file_chooser_set_filename(GTK_FILE_CHOOSER(dialog), argv[1]);
    gboolean selected = FALSE;
    gint64 deadline = g_get_monotonic_time() + 5 * G_TIME_SPAN_SECOND;
    while (!selected && g_get_monotonic_time() < deadline) {
        while (gtk_events_pending())
            gtk_main_iteration();
        gchar *filename = gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog));
        selected = g_strcmp0(filename, argv[1]) == 0;
        g_free(filename);
        if (!selected)
            g_usleep(10000);
    }
    gtk_widget_destroy(dialog);
    if (!selected) {
        g_printerr("File chooser could not select the SVG file\n");
        return 1;
    }
    g_print("SVG, themed icon, GVfs and file chooser: OK\n");
    return 0;
}
