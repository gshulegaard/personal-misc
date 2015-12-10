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

package org.glyptodon.guacamole.skeleton.tunnel.websocket;

import java.util.Map;
import javax.websocket.EndpointConfig;
import javax.websocket.HandshakeResponse;
import javax.websocket.Session;
import javax.websocket.server.HandshakeRequest;
import javax.websocket.server.ServerEndpointConfig;
import org.glyptodon.guacamole.GuacamoleException;
import org.glyptodon.guacamole.net.GuacamoleTunnel;
import org.glyptodon.guacamole.skeleton.tunnel.TunnelRequestUtility;
import org.glyptodon.guacamole.websocket.GuacamoleWebSocketTunnelEndpoint;

/**
 * Simple WebSocket tunnel implementation. All configuration is abstracted
 * within the TunnelRequestUtility.
 */
public class WebSocketTunnelEndpoint extends GuacamoleWebSocketTunnelEndpoint {

    /**
     * Unique string which shall be used to store the GuacamoleTunnel
     * associated with a WebSocket connection.
     */
    private static final String TUNNEL_USER_PROPERTY = "WS_GUAC_TUNNEL";

    /**
     * Unique string which shall be used to store any GuacamoleException that
     * occurs while retrieving the tunnel during the handshake.
     */
    private static final String ERROR_USER_PROPERTY = "WS_GUAC_TUNNEL_ERROR";

    /**
     * Configurator implementation which stores the requested GuacamoleTunnel
     * within the user properties. The GuacamoleTunnel will be later retrieved
     * during the connection process.
     */
    public static class Configurator extends ServerEndpointConfig.Configurator {

        @Override
        public void modifyHandshake(ServerEndpointConfig config, HandshakeRequest request, HandshakeResponse response) {

            super.modifyHandshake(config, request, response);
            
            // Attempt tunnel creation
            Map<String, Object> userProperties = config.getUserProperties();
            userProperties.clear();
            try {

                // Store new tunnel within user properties
                GuacamoleTunnel tunnel = TunnelRequestUtility.createTunnel(new WebSocketTunnelRequest(request));
                if (tunnel != null)
                    userProperties.put(TUNNEL_USER_PROPERTY, tunnel);

            }
            catch (GuacamoleException e) {
                userProperties.put(ERROR_USER_PROPERTY, e);
            }

        }

    }
    
    @Override
    protected GuacamoleTunnel createTunnel(Session session, EndpointConfig config) throws GuacamoleException {

        /*
         * Any configuration of the tunnel based on the content of the request
         * should be done within TunnelRequestUtility.
         */

        // Throw any error that occurred during tunnel creation
        Map<String, Object> userProperties = config.getUserProperties();
        GuacamoleException tunnelError = (GuacamoleException) userProperties.get(ERROR_USER_PROPERTY);
        if (tunnelError != null)
            throw tunnelError;

        // Return created tunnel, if any
        return (GuacamoleTunnel) userProperties.get(TUNNEL_USER_PROPERTY);

    }

}
