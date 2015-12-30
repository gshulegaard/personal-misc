/*
 * Copyright (C) 2015 Glyptodon LLC
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

package org.glyptodon.guacamole.skeleton.tunnel;

import java.util.List;
import org.glyptodon.guacamole.GuacamoleException;
import org.glyptodon.guacamole.net.GuacamoleSocket;
import org.glyptodon.guacamole.net.GuacamoleTunnel;
import org.glyptodon.guacamole.net.InetGuacamoleSocket;
import org.glyptodon.guacamole.net.SimpleGuacamoleTunnel;
import org.glyptodon.guacamole.protocol.ConfiguredGuacamoleSocket;
import org.glyptodon.guacamole.protocol.GuacamoleClientInformation;
import org.glyptodon.guacamole.protocol.GuacamoleConfiguration;

/**
 * Utility class that takes a standard request from the Guacamole JavaScript
 * client and produces the corresponding GuacamoleTunnel.
 *
 * @author Michael Jumper
 */
public class TunnelRequestUtility {

    /**
     * This class is a utility class and need not be instantiated.
     */
    private TunnelRequestUtility() {}

    /**
     * Reads and returns the client information provided within the given
     * request. Client information is included in the parameters of the
     * request, passed through the connect string given to connect() of the
     * Guacamole JavaScript client.
     *
     * @param request
     *     The request to retrieve client information from.
     *
     * @return GuacamoleClientInformation
     *     An object containing information about the client sending the tunnel
     *     request.
     */
    public static GuacamoleClientInformation getClientInformation(TunnelRequest request) {

        // Get client information
        GuacamoleClientInformation info = new GuacamoleClientInformation();

        // Set width if provided
        String width = request.getParameter("width");
        if (width != null)
            info.setOptimalScreenWidth(Integer.parseInt(width));

        // Set height if provided
        String height = request.getParameter("height");
        if (height != null)
            info.setOptimalScreenHeight(Integer.parseInt(height));

        // Set resolution if provided
        String dpi = request.getParameter("dpi");
        if (dpi != null)
            info.setOptimalResolution(Integer.parseInt(dpi));

        // Add audio mimetypes
        List<String> audio_mimetypes = request.getParameterValues("audio");
        if (audio_mimetypes != null)
            info.getAudioMimetypes().addAll(audio_mimetypes);

        // Add video mimetypes
        List<String> video_mimetypes = request.getParameterValues("video");
        if (video_mimetypes != null)
            info.getVideoMimetypes().addAll(video_mimetypes);

        return info;

    }

    /**
     * Parses the given request, returning the configuration of the connection
     * requested.
     *
     * @param request
     *     The request to retrieve the configuration information for.
     *
     * @return
     *     The configuration information for the requested connection.
     *
     * @throws GuacamoleException
     *     If an error prevents the configuration information from being
     *     retrieved.
     */
    public static GuacamoleConfiguration getConfiguration(TunnelRequest request)
            throws GuacamoleException {

        /*
         * NOTE: For the sake of this skeleton, this configuration information
         * is hard-coded, but you can determine the connection parameters
         * however you like:
         *
         * http://guac-dev.org/doc/gug/configuring-guacamole.html#connection-configuration
         */

        // Connection information
        GuacamoleConfiguration config = new GuacamoleConfiguration();
        config.setProtocol("vnc");
        config.setParameter("hostname", "localhost");
        config.setParameter("port",     "5902");

        return config;
        
    }

    /**
     * Creates a socket which is connected to an instance of guacd. The
     * handshake phase of the Guacamole protocol will still need to be
     * completed before this socket is used with a tunnel.
     *
     * @return
     *     A socket connected to guacd.
     *
     * @throws GuacamoleException
     *     If an error prevents the socket from being created.
     */
    public static GuacamoleSocket createSocket() throws GuacamoleException {

        /*
         * NOTE: In many cases, you will want to pull this information from a
         * configuration file. The Guacamole API provides Environment and
         * LocalEnvironment if you wish to use guacamole.properties to do this,
         * but the ultimate storage of this information really doesn't matter.
         */

        // Hard-coded guacd connection information
        return new InetGuacamoleSocket("localhost", 4822);

    }

    /**
     * Creates a new tunnel using the parameters present in the given request.
     *
     * @param request
     *     The request describing the tunnel to create.
     *
     * @return
     *     The created tunnel, or null if the tunnel could not be created.
     *
     * @throws GuacamoleException
     *     If an error occurs while creating the tunnel.
     */
    public static GuacamoleTunnel createTunnel(TunnelRequest request)
            throws GuacamoleException {

        // Connect to guacd, configuring the connection based on the request
        GuacamoleSocket socket = new ConfiguredGuacamoleSocket(
            createSocket(),
            getConfiguration(request),
            getClientInformation(request)
        );

        // Create tunnel from now-configured socket
        return new SimpleGuacamoleTunnel(socket);

    }

}
