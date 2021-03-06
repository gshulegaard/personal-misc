/*
 * Copyright (C) 2013 Glyptodon LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include "config.h"

#include "client.h"
#include "rdp_cliprdr.h"
#include "guac_clipboard.h"
#include "guac_iconv.h"

#include <freerdp/channels/channels.h>
#include <freerdp/freerdp.h>
#include <freerdp/utils/event.h>
#include <guacamole/client.h>

#ifdef ENABLE_WINPR
#include <winpr/wtypes.h>
#else
#include "compat/winpr-wtypes.h"
#endif

#ifdef HAVE_FREERDP_CLIENT_CLIPRDR_H
#include <freerdp/client/cliprdr.h>
#else
#include "compat/client-cliprdr.h"
#endif

#include <stdlib.h>
#include <string.h>

void guac_rdp_process_cliprdr_event(guac_client* client, wMessage* event) {

#ifdef LEGACY_EVENT
        switch (event->event_type) {
#else
        switch (GetMessageType(event->id)) {
#endif

            case CliprdrChannel_MonitorReady:
                guac_rdp_process_cb_monitor_ready(client, event);
                break;

            case CliprdrChannel_FormatList:
                guac_rdp_process_cb_format_list(client,
                        (RDP_CB_FORMAT_LIST_EVENT*) event);
                break;

            case CliprdrChannel_DataRequest:
                guac_rdp_process_cb_data_request(client,
                        (RDP_CB_DATA_REQUEST_EVENT*) event);
                break;

            case CliprdrChannel_DataResponse:
                guac_rdp_process_cb_data_response(client,
                        (RDP_CB_DATA_RESPONSE_EVENT*) event);
                break;

            default:
#ifdef LEGACY_EVENT
                guac_client_log(client, GUAC_LOG_INFO,
                        "Unknown cliprdr event type: 0x%x",
                        event->event_type);
#else
                guac_client_log(client, GUAC_LOG_INFO,
                        "Unknown cliprdr event type: 0x%x",
                        GetMessageType(event->id));
#endif

        }

}

void guac_rdp_process_cb_monitor_ready(guac_client* client, wMessage* event) {

    rdpChannels* channels = 
        ((rdp_guac_client_data*) client->data)->rdp_inst->context->channels;

    RDP_CB_FORMAT_LIST_EVENT* format_list =
        (RDP_CB_FORMAT_LIST_EVENT*) freerdp_event_new(
            CliprdrChannel_Class,
            CliprdrChannel_FormatList,
            NULL, NULL);

    /* Received notification of clipboard support. */

    /* Respond with supported format list */
    format_list->formats = (UINT32*) malloc(sizeof(UINT32)*2);
    format_list->formats[0] = CB_FORMAT_TEXT;
    format_list->formats[1] = CB_FORMAT_UNICODETEXT;
    format_list->num_formats = 2;

    freerdp_channels_send_event(channels, (wMessage*) format_list);

}

/**
 * Sends a clipboard data request for the given format.
 */
static void __guac_rdp_cb_request_format(guac_client* client, int format) {

    rdp_guac_client_data* client_data = (rdp_guac_client_data*) client->data;
    rdpChannels* channels = client_data->rdp_inst->context->channels;

    /* Create new data request */
    RDP_CB_DATA_REQUEST_EVENT* data_request =
        (RDP_CB_DATA_REQUEST_EVENT*) freerdp_event_new(
                CliprdrChannel_Class,
                CliprdrChannel_DataRequest,
                NULL, NULL);

    /* Set to requested format */
    client_data->requested_clipboard_format = format;
    data_request->format = format;

    /* Send request */
    freerdp_channels_send_event(channels, (wMessage*) data_request);

}

void guac_rdp_process_cb_format_list(guac_client* client,
        RDP_CB_FORMAT_LIST_EVENT* event) {

    int formats = 0;

    /* Received notification of available data */

    int i;
    for (i=0; i<event->num_formats; i++) {

        /* If plain text available, request it */
        if (event->formats[i] == CB_FORMAT_TEXT)
            formats |= GUAC_RDP_CLIPBOARD_FORMAT_CP1252;
        else if (event->formats[i] == CB_FORMAT_UNICODETEXT)
            formats |= GUAC_RDP_CLIPBOARD_FORMAT_UTF16;

    }

    /* Prefer Unicode to plain text */
    if (formats & GUAC_RDP_CLIPBOARD_FORMAT_UTF16) {
        __guac_rdp_cb_request_format(client, CB_FORMAT_UNICODETEXT);
        return;
    }

    /* Use plain text if Unicode unavailable */
    if (formats & GUAC_RDP_CLIPBOARD_FORMAT_CP1252) {
        __guac_rdp_cb_request_format(client, CB_FORMAT_TEXT);
        return;
    }

    /* Ignore if no supported format available */
    guac_client_log(client, GUAC_LOG_INFO, "Ignoring unsupported clipboard data");

}

void guac_rdp_process_cb_data_request(guac_client* client,
        RDP_CB_DATA_REQUEST_EVENT* event) {

    rdp_guac_client_data* client_data = (rdp_guac_client_data*) client->data;
    rdpChannels* channels = client_data->rdp_inst->context->channels;

    guac_iconv_write* writer;
    const char* input = client_data->clipboard->buffer;
    char* output = malloc(GUAC_RDP_CLIPBOARD_MAX_LENGTH);

    RDP_CB_DATA_RESPONSE_EVENT* data_response;

    /* Determine output encoding */
    switch (event->format) {

        case CB_FORMAT_TEXT:
            writer = GUAC_WRITE_CP1252;
            break;

        case CB_FORMAT_UNICODETEXT:
            writer = GUAC_WRITE_UTF16;
            break;

        default:
            guac_client_log(client, GUAC_LOG_ERROR, 
                    "Server requested unsupported clipboard data type");
            return;

    }

    /* Create new data response */
    data_response = (RDP_CB_DATA_RESPONSE_EVENT*) freerdp_event_new(
                CliprdrChannel_Class,
                CliprdrChannel_DataResponse,
                NULL, NULL);

    /* Set data and size */
    data_response->data = (BYTE*) output;
    guac_iconv(GUAC_READ_UTF8, &input, client_data->clipboard->length,
               writer, &output, GUAC_RDP_CLIPBOARD_MAX_LENGTH);
    data_response->size = ((BYTE*) output) - data_response->data;

    /* Send response */
    freerdp_channels_send_event(channels, (wMessage*) data_response);

}

void guac_rdp_process_cb_data_response(guac_client* client,
        RDP_CB_DATA_RESPONSE_EVENT* event) {

    rdp_guac_client_data* client_data = (rdp_guac_client_data*) client->data;
    char received_data[GUAC_RDP_CLIPBOARD_MAX_LENGTH];

    guac_iconv_read* reader;
    const char* input = (char*) event->data;
    char* output = received_data;

    /* Find correct source encoding */
    switch (client_data->requested_clipboard_format) {

        /* Non-Unicode */
        case CB_FORMAT_TEXT:
            reader = GUAC_READ_CP1252;
            break;

        /* Unicode (UTF-16) */
        case CB_FORMAT_UNICODETEXT:
            reader = GUAC_READ_UTF16;
            break;

        default:
            guac_client_log(client, GUAC_LOG_ERROR, "Requested clipboard data in "
                    "unsupported format %i",
                    client_data->requested_clipboard_format);
            return;

    }

    /* Convert send clipboard data */
    if (guac_iconv(reader, &input, event->size,
            GUAC_WRITE_UTF8, &output, sizeof(received_data))) {

        int length = strnlen(received_data, sizeof(received_data));
        guac_common_clipboard_reset(client_data->clipboard, "text/plain");
        guac_common_clipboard_append(client_data->clipboard, received_data, length);
        guac_common_clipboard_send(client_data->clipboard, client);

    }

}

